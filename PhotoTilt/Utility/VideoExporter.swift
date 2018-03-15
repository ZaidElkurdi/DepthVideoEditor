////
////  VideoExporter.swift
////  PhotoTilt
////
////  Created by Zaid Elkurdi on 2/26/18.
////  Copyright © 2018 Zaid Elkurdi. All rights reserved.
////
//
//import AVFoundation
//import AVKit
//
//class VideoExporter {
//  private var frameNumber: Int64 = 0
//  private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
//  private var videoWriter: AVAssetWriter?
//  private var writerInput: AVAssetWriterInput?
//  
//  func startWriting() {
//    let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
//    guard let videoFileUrl = paths.first?.appendingPathComponent("video.mov") else { return } // ERROR
//    
//    try? FileManager.default.removeItem(at: videoFileUrl)
//    
//    videoWriter = try? AVAssetWriter(outputURL: videoFileUrl, fileType: .mov)
//    guard let videoWriter = videoWriter else { return } // ERROR
//    let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: nil)
//    writerInput.expectsMediaDataInRealTime = true
//    videoWriter.add(writerInput)
//    self.writerInput = writerInput
//    
//    pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes:
//      [ kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)])
//    
//    if videoWriter.startWriting() {
//      depthDataBuffer = []
//      frameNumber = 0
//      videoWriter.startSession(atSourceTime: kCMTimeZero)
//    }
//  }
//  
//  func finishWriting(writeCompletion: @escaping () -> Void) {
//    writerInput?.markAsFinished()
//    videoWriter?.finishWriting(completionHandler: writeCompletion)
//  }
//  
//  func append(sampleBuffer: CMSampleBuffer) {
//    if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer), let writerInput = writerInput, writerInput.isReadyForMoreMediaData {
//      pixelBufferAdaptor?.append(imageBuffer, withPresentationTime: CMTimeMake(frameNumber, 30))
//      frameNumber += 1
//    }
//  }
//}

