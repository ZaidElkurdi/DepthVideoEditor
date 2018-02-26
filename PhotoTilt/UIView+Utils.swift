//
//  UIView+Utils.swift
//  PhotoTilt
//
//  Created by Zaid Elkurdi on 2/10/18.
//  Copyright © 2018 Zaid Elkurdi. All rights reserved.
//

import UIKit

extension CVPixelBuffer
{
  /// Deep copy a CVPixelBuffer:
  ///   http://stackoverflow.com/questions/38335365/pulling-data-from-a-cmsamplebuffer-in-order-to-create-a-deep-copy
  func copy() -> CVPixelBuffer
  {
    precondition(CFGetTypeID(self) == CVPixelBufferGetTypeID(), "copy() cannot be called on a non-CVPixelBuffer")
    
    var _copy: CVPixelBuffer?
    
    CVPixelBufferCreate(
      nil,
      CVPixelBufferGetWidth(self),
      CVPixelBufferGetHeight(self),
      CVPixelBufferGetPixelFormatType(self),
      CVBufferGetAttachments(self, .shouldPropagate),
      &_copy)
    
    guard let copy = _copy else { fatalError() }
    
    CVPixelBufferLockBaseAddress(self, .readOnly)
    CVPixelBufferLockBaseAddress(copy, [])
    defer
    {
      CVPixelBufferUnlockBaseAddress(copy, [])
      CVPixelBufferUnlockBaseAddress(self, .readOnly)
    }
    
    for plane in 0 ..< CVPixelBufferGetPlaneCount(self)
    {
      let dest        = CVPixelBufferGetBaseAddressOfPlane(copy, plane)
      let source      = CVPixelBufferGetBaseAddressOfPlane(self, plane)
      let height      = CVPixelBufferGetHeightOfPlane(self, plane)
      let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(self, plane)
      
      memcpy(dest, source, height * bytesPerRow)
    }
    
    return copy
  }
}

extension NSLayoutConstraint {
  class func activate(_ constraints: [[NSLayoutConstraint]]) {
    constraints.forEach({ NSLayoutConstraint.activate($0) })
  }
  
  class func constraints(withVisualFormats formats: [String],
                         options opts: NSLayoutFormatOptions = [],
                         metrics: [String : Any]?,
                         views: [String : Any]) -> [[NSLayoutConstraint]] {
    return formats.map({ NSLayoutConstraint.constraints(withVisualFormat: $0, options: opts, metrics: metrics, views: views) })
  }
}

extension CGRect {
  var center: CGPoint {
    get {
      let centerX = origin.x + (size.width / 2)
      let centerY = origin.y + (size.height / 2)
      return CGPoint(x: centerX, y: centerY)
    }
    set(newCenter) {
      origin.x = newCenter.x - (size.width / 2)
      origin.y = newCenter.y - (size.height / 2)
    }
  }
}

extension UIView {
  func addSubviews(_ views: [UIView]) {
    views.forEach({ addSubview($0) })
  }
}
