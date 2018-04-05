//
//  VideoExporter.swift
//  PhotoTilt
//
//  Created by Zaid Elkurdi on 2/26/18.
//  Copyright © 2018 Zaid Elkurdi. All rights reserved.
//

import AVFoundation
import AVKit
import Photos

class VideoExporter {
  static func exportAsset(_ videoAsset: AVAsset, composition: AVVideoComposition?, exportCompletion: @escaping (Bool) -> Void) {
    let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
    guard let videoFileUrl = paths.first?.appendingPathComponent("exported-video.mov") else {
      exportCompletion(false)
      return
    }

    try? FileManager.default.removeItem(at: videoFileUrl)

    guard let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality) else {
      exportCompletion(false)
      return
    }

    exportSession.outputFileType = AVFileType.mov
    exportSession.outputURL = videoFileUrl
    exportSession.videoComposition = composition

    exportSession.exportAsynchronously(completionHandler: {
      guard exportSession.status == .completed else {
        exportCompletion(false)
        return
      }

      do {
        try PHPhotoLibrary.shared().performChangesAndWait({
          PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoFileUrl)
        })
      } catch {
        exportCompletion(false)
        return
      }

      exportCompletion(true)
    })
  }
}

