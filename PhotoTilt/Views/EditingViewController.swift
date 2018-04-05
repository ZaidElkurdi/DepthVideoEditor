//
//  EditingViewController.swift
//  PhotoTilt
//
//  Created by Zaid Elkurdi on 2/13/18.
//  Copyright © 2018 Zaid Elkurdi. All rights reserved.
//

import AVFoundation
import MBProgressHUD
import UIKit

class EditingViewController: UIViewController {
  enum VideoSourceType {
    case video
    case depth
    case mask

    var buttonTitle: String {
      switch self {
      case .video:
        return "Show Depth Data"
      case .depth:
        return "Show Mask"
      case .mask:
        return "Show Video"
      }
    }

    var next: VideoSourceType {
      switch self {
      case .video:
        return .depth
      case .depth:
        return .mask
      case .mask:
        return .video
      }
    }
  }

  private var composition: AVVideoComposition?
  private var currentVideoSource = VideoSourceType.video
  private var selectedFilter: DepthImageFilters.FilterType = .color
  private let depthData: [CVPixelBuffer]
  private let depthDataImages: [CIImage]
  private var transformedDepthImages: [CIImage?]
  private let videoAsset: AVAsset
  private lazy var editingView: EditingView = EditingView(onVideoSourceToggled: { [weak self] videoSourceType in
    guard let `self` = self else { return }
    self.currentVideoSource = videoSourceType
    self.editingView.effectEditingControlsView.isHidden = videoSourceType == .depth
    self.editingView.depthEditingControlsView.isHidden = videoSourceType != .depth
  })
  private var recordedVideo: AVPlayerItem?
  private lazy var leftSwipeRecognizer: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipeRecognized))
  private lazy var rightSwipeRecognizer: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipeRecognized))
  private var avPlayer: AVPlayer?
  private var recordedVideoPreviewLayer: AVPlayerLayer?
  
  private let context = CIContext()
  private lazy var depthFilters: DepthImageFilters = DepthImageFilters(context: self.context)
  
  convenience init() {
    let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
    guard let videoFileUrl = paths.first?.appendingPathComponent("video.mov") else { fatalError() }
    self.init(videoAsset: AVAsset(url: videoFileUrl), depthData: [])
  }
  
  init(videoAsset: AVAsset, depthData: [CVPixelBuffer]) {
    self.videoAsset = videoAsset
    self.depthData = depthData
    
    var transformedDepthData: [CIImage] = []
    for currBuffer in depthData {
      transformedDepthData.append(CIImage.init(cvPixelBuffer: currBuffer).oriented(.right))
    }
    depthDataImages = transformedDepthData

    self.transformedDepthImages = Array(repeating: nil, count: depthDataImages.count)
    
    super.init(nibName: nil, bundle: nil)
    
    leftSwipeRecognizer.direction = .left
    leftSwipeRecognizer.delegate = self
    editingView.addGestureRecognizer(leftSwipeRecognizer)
    
    rightSwipeRecognizer.direction = .right
    rightSwipeRecognizer.delegate = self
    editingView.addGestureRecognizer(rightSwipeRecognizer)
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveTapped))
    
    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { _ in
      self.avPlayer?.seek(to: kCMTimeZero)
      self.avPlayer?.play()
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func loadView() {
    super.loadView()
    view = editingView
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    playVideo()
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    recordedVideoPreviewLayer?.frame = editingView.videoPreviewView.frame
  }
  
  @objc private func saveTapped() {
    let progressHUD = MBProgressHUD.showAdded(to: self.view, animated: true)
    progressHUD.label.text = "Exporting..."

    VideoExporter.exportAsset(videoAsset, composition: composition, exportCompletion: { [weak self] success in
      DispatchQueue.main.async {
        progressHUD.hide(animated: true)

        if !success {
          let errorHUD = MBProgressHUD.showAdded(to: self.view, animated: true)
          errorHUD.mode = .text
          errorHUD.label.text = "Error exporting video"
          errorHUD.hide(animated: true, afterDelay: 3.0)
        }
      }
    })
  }
  
  @objc private func swipeRecognized(_ recognizer: UISwipeGestureRecognizer) {
    if recognizer.direction == .left {
      selectedFilter = selectedFilter.nextFilter
    } else if recognizer.direction == .right {
      selectedFilter = selectedFilter.prevFilter
    }
  }

  private func playVideo() {
    let videoComposition = AVVideoComposition(asset: videoAsset, applyingCIFiltersWithHandler: { [weak self] request in
      guard let `self` = self else { return }
      // Clamp to avoid blurring transparent pixels at the image edges
      let source = request.sourceImage.clampedToExtent()
      
      let depthDataIndex = Int(request.compositionTime.convertScale(30, method: .quickTime).value)
      
      guard self.depthData.count > depthDataIndex else {
        request.finish(with: source, context: nil)
        return
      }
      
      let depthImage = self.depthDataImages[depthDataIndex].applyingFilter("CINoiseReduction", parameters: self.editingView.depthEditingControlsView.noiseReductionParameters)
      
      let maxToDim = max(request.sourceImage.extent.width, request.sourceImage.extent.height)
      let maxFromDim = max(depthImage.extent.width, depthImage.extent.height)
      
      let scale = maxToDim / maxFromDim
      
      if self.currentVideoSource == .depth {
        request.finish(with: depthImage.applyingFilter("CIBicubicScaleTransform", parameters: ["inputScale": scale]), context: nil)
        return
      }
      
      let mask = self.depthFilters.createMask(for: depthImage, slope: CGFloat(self.editingView.effectEditingControlsView.slopeSlider.value * 10), width: CGFloat(self.editingView.effectEditingControlsView.widthSlider.value), withMinFocus: self.editingView.effectEditingControlsView.focusSlider.selectedMinValue / 100, maxFocus: self.editingView.effectEditingControlsView.focusSlider.selectedMaxValue / 100, blur: CGFloat(self.editingView.effectEditingControlsView.blurSlider.value), scale: scale)

      if self.currentVideoSource == .mask {
        request.finish(with: mask, context: nil)
        return
      }

      if let filteredImage = self.transformedFrame(source, mask: mask, filter: self.selectedFilter)?.cropped(to: request.sourceImage.extent) {
        request.finish(with: filteredImage, context: nil)
      } else {
        request.finish(with: source, context: nil)
      }
    })

    composition = videoComposition
    
    let recordedVideo = AVPlayerItem(asset: videoAsset)
    recordedVideo.videoComposition = videoComposition
    
    let avPlayer = AVPlayer(playerItem: recordedVideo)
    
    let recordedVideoPreviewLayer = AVPlayerLayer(player: avPlayer)
    recordedVideoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    recordedVideoPreviewLayer.frame = editingView.videoPreviewView.frame
    editingView.videoPreviewView.layer.addSublayer(recordedVideoPreviewLayer)
    editingView.playerLayer = recordedVideoPreviewLayer
    
    avPlayer.play()
    
    self.recordedVideo = recordedVideo
    self.avPlayer = avPlayer
    self.recordedVideoPreviewLayer = recordedVideoPreviewLayer
  }
  
  private func transformedFrame(_ image: CIImage, mask: CIImage, filter: DepthImageFilters.FilterType) -> CIImage? {
    switch filter {
    case .blur:
      return depthFilters.blur(image: image, mask: mask)
    case .color:
      return depthFilters.colorHighlight(image: image, mask: mask)
    case .frozen:
      return nil
    }
  }
}

extension EditingViewController: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    return touch.view == editingView.videoPreviewView
  }
}
