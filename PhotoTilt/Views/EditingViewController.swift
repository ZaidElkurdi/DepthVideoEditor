//
//  EditingViewController.swift
//  PhotoTilt
//
//  Created by Zaid Elkurdi on 2/13/18.
//  Copyright © 2018 Zaid Elkurdi. All rights reserved.
//

import AVFoundation
import UIKit

class EditingViewController: UIViewController {
  enum VideoSourceType {
    case video
    case depth
  }
  
  private var currentVideoSource = VideoSourceType.video
  private var selectedFilter: DepthImageFilters.FilterType = .color
  private let depthData: [CVPixelBuffer]
  private let depthDataImages: [CIImage]
  private var transformedDepthImages: [CIImage]
  private var exportSession: AVAssetExportSession?
  private let videoAsset: AVAsset
  private lazy var editingView: EditingView = EditingView(onVideoSourceToggled: { [weak self] showVideo in
    guard let `self` = self else { return }
    self.currentVideoSource = showVideo ? .video : .depth
    self.editingView.effectEditingControlsView.isHidden = !showVideo
    self.editingView.depthEditingControlsView.isHidden = showVideo
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
//    exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality)
//    exportSession.outputFileType = AVFileTypeQuickTimeMovie
//    exportSession.outputURL = outURL
//    exportSession.videoComposition = composition
//    
//    exportSession.exportAsynchronouslyWithComplet
  }
  
  @objc private func swipeRecognized(_ recognizer: UISwipeGestureRecognizer) {
    if recognizer.direction == .left {
      selectedFilter = selectedFilter.nextFilter
    } else if recognizer.direction == .right {
      selectedFilter = selectedFilter.prevFilter
    }
  }
  
  private func playVideo() {
    let composition = AVVideoComposition(asset: videoAsset, applyingCIFiltersWithHandler: { [weak self] request in
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
      
      let mask = self.depthFilters.createMask(for: depthImage, slope: CGFloat(self.editingView.effectEditingControlsView.slopeSlider.value * 10), width: CGFloat(self.editingView.effectEditingControlsView.widthSlider.value), withMinFocus: self.editingView.effectEditingControlsView.focusSlider.selectedMinValue / 100, maxFocus: self.editingView.effectEditingControlsView.focusSlider.selectedMaxValue / 100, andScale: scale)
      if let filteredImage = self.transformedFrame(source, mask: mask, filter: self.selectedFilter)?.cropped(to: request.sourceImage.extent) {
        request.finish(with: filteredImage, context: nil)
      } else {
        request.finish(with: source, context: nil)
      }
    })
    
    let recordedVideo = AVPlayerItem(asset: videoAsset)
    recordedVideo.videoComposition = composition
    
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
