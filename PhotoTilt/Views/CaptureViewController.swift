//
//  CaptureViewController.swift
//  PhotoTilt
//
//  Created by Zaid Elkurdi on 2/9/18.
//  Copyright © 2018 Zaid Elkurdi. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class CaptureViewController: UIViewController {
  private let captureSession = AVCaptureSession()
  
  fileprivate lazy var captureView: CaptureView = CaptureView(onCaptureButtonTapped: { [weak self] isActive in
    self?.setRecording(isActive)
  })
  
  private var depthDataBuffer: [CVPixelBuffer] = []
  private let dataOutputQueue = DispatchQueue(label: "Video Data", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
  private let depthDataOutput = AVCaptureDepthDataOutput()
  private var tapGestureRecognizer: UITapGestureRecognizer?
  private var isRecording = false
  private var outputSynchronizer: AVCaptureDataOutputSynchronizer?
  private let photoOutput = AVCapturePhotoOutput()
  private var captureSessionIsConfigured = false
  private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
  private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera,
                                                                                           .builtInWideAngleCamera],
                                                                             mediaType: .video,
                                                                             position: .unspecified)
  private var videoDeviceInput: AVCaptureDeviceInput?
  private let videoDataOutput = AVCaptureVideoDataOutput()
  private var videoWriter: AVAssetWriter?
  private var writerInput: AVAssetWriterInput?
  
  var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
  var frameNumber: Int64 = 0
  
  override func loadView() {
    super.loadView()
    view = captureView
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configureSession()
    captureSessionIsConfigured = true
    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapRecognized))
    tapGestureRecognizer.delegate = self
    self.tapGestureRecognizer = tapGestureRecognizer
    captureView.addGestureRecognizer(tapGestureRecognizer)

  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if captureSessionIsConfigured && !captureSession.isRunning {
      captureSession.startRunning()
    }
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    videoPreviewLayer?.frame = captureView.cameraPreviewView.layer.bounds
  }
  
  @objc private func tapRecognized(_ gestureRecognizer: UIGestureRecognizer) {
    guard let videoPreviewLayer = videoPreviewLayer else { return }
    let devicePoint = videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: gestureRecognizer.location(in: gestureRecognizer.view))
    focus(with: .autoFocus, exposureMode: .autoExpose, at: devicePoint, monitorSubjectAreaChange: true)
  }
  
  @objc func subjectAreaDidChange(notification: NSNotification) {
    let devicePoint = CGPoint(x: 0.5, y: 0.5)
    focus(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: false)
  }
  
  private func focus(with focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {
    
    guard let device = self.videoDeviceInput?.device else { return }
    do {
      try device.lockForConfiguration()

      /*
       Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
       Call set(Focus/Exposure)Mode() to apply the new point of interest.
       */
      if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
        device.focusPointOfInterest = devicePoint
        device.focusMode = focusMode
      }

      if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
        device.exposurePointOfInterest = devicePoint
        device.exposureMode = exposureMode
      }

      device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
      device.unlockForConfiguration()
    } catch {
      print("Could not lock device for configuration: \(error)")
    }
  }
  
  private func configureSession() {
    let defaultVideoDevice: AVCaptureDevice? = videoDeviceDiscoverySession.devices.first
    
    guard let videoDevice = defaultVideoDevice else {
      print("Could not find any video device")
      return
    }
    
    do {
      videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
    } catch {
      print("Could not create video device input: \(error)")
      return
    }
    
    captureSession.beginConfiguration()
    captureSession.sessionPreset = AVCaptureSession.Preset.photo
    
    // Add a video input
    guard let videoDeviceInput = videoDeviceInput, captureSession.canAddInput(videoDeviceInput), captureSession.canAddInput(videoDeviceInput) else {
      print("Could not add video device input to the session")
      captureSession.commitConfiguration()
      return
    }
    captureSession.addInput(videoDeviceInput)
    
    NotificationCenter.default.addObserver(self, selector: #selector(subjectAreaDidChange), name: .AVCaptureDeviceSubjectAreaDidChange, object: videoDeviceInput.device)
    
    // Add a video data output
    if captureSession.canAddOutput(videoDataOutput) {
      captureSession.addOutput(videoDataOutput)
      videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
    } else {
      print("Could not add video data output to the session")
      captureSession.commitConfiguration()
      return
    }
    
    // Add photo output
    if captureSession.canAddOutput(photoOutput) {
      captureSession.addOutput(photoOutput)
      
      photoOutput.isHighResolutionCaptureEnabled = true
      
      if photoOutput.isDepthDataDeliverySupported {
        photoOutput.isDepthDataDeliveryEnabled = true
      }
      
    } else {
      print("Could not add photo output to the session")
      captureSession.commitConfiguration()
      return
    }
    
    // Add a depth data output
    if captureSession.canAddOutput(depthDataOutput) {
      captureSession.addOutput(depthDataOutput)
      depthDataOutput.isFilteringEnabled = true
      if let connection = depthDataOutput.connection(with: .depthData) {
        connection.isEnabled = true
      } else {
        print("No AVCaptureConnection")
      }
    } else {
      print("Could not add depth data output to the session")
      captureSession.commitConfiguration()
      return
    }
    
    // Use an AVCaptureDataOutputSynchronizer to synchronize the video data and depth data outputs.
    // The first output in the dataOutputs array, in this case the AVCaptureVideoDataOutput, is the "master" output.
    outputSynchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [videoDataOutput, depthDataOutput])
    outputSynchronizer!.setDelegate(self, queue: dataOutputQueue)
    
    if self.photoOutput.isDepthDataDeliverySupported {
      // Cap the video framerate at the max depth framerate
      if let frameDuration = videoDevice.activeDepthDataFormat?.videoSupportedFrameRateRanges.first?.minFrameDuration {
        do {
          try videoDevice.lockForConfiguration()
          videoDevice.activeVideoMinFrameDuration = frameDuration
          videoDevice.unlockForConfiguration()
        } catch {
          print("Could not lock device for configuration: \(error)")
        }
      }
    }
    
    captureSession.commitConfiguration()
    
    let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    videoPreviewLayer.connection?.videoOrientation = .portrait
    self.videoPreviewLayer = videoPreviewLayer
    videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    captureView.cameraPreviewView.layer.addSublayer(videoPreviewLayer)
    captureSession.startRunning()
    
    videoDataOutput.connection(with: .video)?.videoOrientation = .portrait
    depthDataOutput.connection(with: .video)?.videoOrientation = .portrait
  }
  
  private func startRecording() {
    guard captureSession.isRunning else { return }
    
    let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
    guard let videoFileUrl = paths.first?.appendingPathComponent("video.mov") else { return } // ERROR
    
    try? FileManager.default.removeItem(at: videoFileUrl)
    
    videoWriter = try? AVAssetWriter(outputURL: videoFileUrl, fileType: .mov)
    guard let videoWriter = videoWriter else { return } // ERROR
    let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: nil)
    writerInput.expectsMediaDataInRealTime = true
    videoWriter.add(writerInput)
    self.writerInput = writerInput
    
    pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes:
      [ kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)])
    
    if videoWriter.startWriting() {
      depthDataBuffer = []
      frameNumber = 0
      videoWriter.startSession(atSourceTime: kCMTimeZero)
    }
  }
  
  private func stopRecording(writeCompletion: @escaping () -> Void) {
    captureSession.stopRunning()
    writerInput?.markAsFinished()
    videoWriter?.finishWriting(completionHandler: writeCompletion)
  }
  
  
  private func setRecording(_ isRecording: Bool) {
    if isRecording {
      startRecording()
    } else {
      stopRecording(writeCompletion: { [weak self] in
        guard let `self` = self else { return }
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        if let videoFileUrl = paths.first?.appendingPathComponent("video.mov") {
          DispatchQueue.main.async {
            let editingViewController = EditingViewController(videoAsset: AVAsset(url: videoFileUrl), depthData: self.depthDataBuffer)
            self.navigationController?.pushViewController(editingViewController, animated: true)
          }
        }
      })
    }
    self.isRecording = isRecording
  }

  fileprivate func processVideo(sampleBuffer: CMSampleBuffer) -> Bool {
    if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer), let writerInput = writerInput, writerInput.isReadyForMoreMediaData {
      pixelBufferAdaptor?.append(imageBuffer, withPresentationTime: CMTimeMake(frameNumber, 30))
      frameNumber += 1
      return true
    }
    return false
  }
}

extension CaptureViewController: AVCaptureDataOutputSynchronizerDelegate, AVCaptureDepthDataOutputDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
  }
  
  func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {
    guard isRecording else { return }
    
    guard let syncedVideoData: AVCaptureSynchronizedSampleBufferData = synchronizedDataCollection.synchronizedData(for: videoDataOutput) as? AVCaptureSynchronizedSampleBufferData else {
      return
    }

    guard !syncedVideoData.sampleBufferWasDropped else {
      let droppedReason = syncedVideoData.droppedReason
      switch droppedReason {
      case .discontinuity:
        print("discont")
      case .lateData:
        print("late")
      case .outOfBuffers:
        print("Out of buffers")
      case .none:
        print("none")
      }
      print("Dropping sample buffer")
      return
    }
    
    let videoSampleBuffer = syncedVideoData.sampleBuffer
    guard let syncedDepthData: AVCaptureSynchronizedDepthData = synchronizedDataCollection.synchronizedData(for: depthDataOutput) as? AVCaptureSynchronizedDepthData, !syncedDepthData.depthDataWasDropped else {
      print("Dropped depth data")
      return
    }

    let convertedDepthData = syncedDepthData.depthData.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32).depthDataMap
    convertedDepthData.normalize()

    let pixelBuffer = convertedDepthData

    CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    let bufferWidth = CVPixelBufferGetWidth(pixelBuffer)
    let bufferHeight = CVPixelBufferGetHeight(pixelBuffer)
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)

    // Copy the pixel buffer
    var pixelBufferCopy: CVPixelBuffer? = nil
    let status = CVPixelBufferCreate(kCFAllocatorDefault, bufferWidth, bufferHeight, kCVPixelFormatType_DisparityFloat32, nil, &pixelBufferCopy);
    if let pixelBufferCopy = pixelBufferCopy {
      CVPixelBufferLockBaseAddress(pixelBufferCopy, CVPixelBufferLockFlags(rawValue: 0))
      let copyBaseAddress = CVPixelBufferGetBaseAddress(pixelBufferCopy)
      memcpy(copyBaseAddress, baseAddress, bufferHeight * bytesPerRow)
      CVPixelBufferUnlockBaseAddress(pixelBufferCopy, CVPixelBufferLockFlags(rawValue: 0))

      depthDataBuffer.append(pixelBufferCopy)
      if !processVideo(sampleBuffer: videoSampleBuffer) {
        print("Dropping frame")
        let _ = depthDataBuffer.popLast()
        frameNumber -= 1
      }
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
  }
}

extension CaptureViewController: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    return touch.view == captureView.cameraPreviewView
  }
}
