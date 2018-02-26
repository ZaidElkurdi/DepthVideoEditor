/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit

enum MaskParams {
  static let slope: CGFloat = 4.0
  static let width: CGFloat = 0.1
}

class DepthImageFilters {
  enum FilterType {
    case blur
    case color
    case frozen
    
    static let allValues: [FilterType] = [.blur, .color, .frozen]
    
    var nextFilter: FilterType {
      guard let filterIndex = FilterType.allValues.index(of: self) else { return self }
      return FilterType.allValues[(filterIndex + 1) % FilterType.allValues.count]
    }
    
    var prevFilter: FilterType {
      guard let filterIndex = FilterType.allValues.index(of: self) else { return self }
      return FilterType.allValues[(filterIndex - 1) < 0 ? FilterType.allValues.count + (filterIndex - 1) : filterIndex - 1]
    }
  }
  
  var context: CIContext
  
  init(context: CIContext) {
    self.context = context
  }
  
  init() {
    context = CIContext()
  }
  
  func createMask(for depthImage: CIImage, slope: CGFloat, width: CGFloat, withMinFocus minFocus: CGFloat, maxFocus: CGFloat, andScale scale: CGFloat) -> CIImage {
    
    let s1 = slope
    let s2 = -slope
    let filterWidth =  2 / slope + width
    let b1 = -s1 * (minFocus - filterWidth / 2)
    let b2 = -s2 * (maxFocus + filterWidth / 2)
    
    let mask0 = depthImage
      .applyingFilter("CIColorMatrix", parameters: [
        "inputRVector": CIVector(x: s1, y: 0, z: 0, w: 0),
        "inputGVector": CIVector(x: 0, y: s1, z: 0, w: 0),
        "inputBVector": CIVector(x: 0, y: 0, z: s1, w: 0),
        "inputBiasVector": CIVector(x: b1, y: b1, z: b1, w: 0)])
      .applyingFilter("CIColorClamp")
    
    let mask1 = depthImage
      .applyingFilter("CIColorMatrix", parameters: [
        "inputRVector": CIVector(x: s2, y: 0, z: 0, w: 0),
        "inputGVector": CIVector(x: 0, y: s2, z: 0, w: 0),
        "inputBVector": CIVector(x: 0, y: 0, z: s2, w: 0),
        "inputBiasVector": CIVector(x: b2, y: b2, z: b2, w: 0)])
      .applyingFilter("CIColorClamp")
    
    let combinedMask = mask0.applyingFilter("CIDarkenBlendMode", parameters: ["inputBackgroundImage" : mask1])

    let mask = combinedMask.applyingFilter("CIBicubicScaleTransform", parameters: ["inputScale": scale])
    
    return mask
  }
  
  func spotlightHighlight(image: CIImage, mask: CIImage, orientation: UIImageOrientation = .up) -> UIImage? {
    
    let output = image.applyingFilter("CIBlendWithMask", parameters: ["inputMaskImage": mask])
    
    guard let cgImage = context.createCGImage(output, from: output.extent) else {
      return nil
    }
    
    return UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
  }

  func colorHighlight(image: CIImage, mask: CIImage, orientation: UIImageOrientation = .up) -> CIImage? {
    
    let greyscale = image.applyingFilter("CIPhotoEffectMono")
    return image.applyingFilter("CIBlendWithMask", parameters: ["inputBackgroundImage" : greyscale,
                                                                      "inputMaskImage": mask])
//
//    guard let cgImage = context.createCGImage(output, from: output.extent) else {
//      return nil
    }
    
//    return CIImage.init(image: UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation))
//  }
  
  
  func blur(image: CIImage, mask: CIImage, orientation: UIImageOrientation = .up) -> CIImage? {
    
    let invertedMask = mask.applyingFilter("CIColorInvert")
    return image.applyingFilter("CIMaskedVariableBlur", parameters: ["inputMask" : invertedMask,
                                                                           "inputRadius": 15.0])
  }
}


