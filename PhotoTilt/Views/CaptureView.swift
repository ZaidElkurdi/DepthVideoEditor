//
//  CaptureView.swift
//  PhotoTilt
//
//  Created by Zaid Elkurdi on 2/13/18.
//  Copyright © 2018 Zaid Elkurdi. All rights reserved.
//

import UIKit

class CaptureView: UIView {
  private let captureButton: CaptureButton
  let bottomView = UIView()
  let cameraPreviewView = UIView()
  
  let focusSlider = UISlider()
  
  init(onCaptureButtonTapped: @escaping (Bool) -> Void) {
    captureButton = CaptureButton(onTap: onCaptureButtonTapped)
    super.init(frame: .zero)
    bottomView.addSubview(captureButton)
    addSubviews([cameraPreviewView, bottomView, focusSlider])
    installConstraints()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func installConstraints() {
    let views = [
      "bottomView": bottomView,
      "cameraPreviewView": cameraPreviewView,
      "captureButton": captureButton,
      "focusSlider": focusSlider,
    ]
    
    let metrics = [
      "captureButtonSize": 80
    ]
    
    views.values.forEach({ $0.translatesAutoresizingMaskIntoConstraints = false })
    
    NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormats: [
      "H:|[cameraPreviewView]|",
      "H:|[bottomView]|",
      "V:|-90-[cameraPreviewView][bottomView(150)]|",
      "H:[captureButton(captureButtonSize)]",
      "V:[captureButton(captureButtonSize)]"
      ], metrics: metrics, views: views))
    
    NSLayoutConstraint.activate([captureButton.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor),
                                 captureButton.centerXAnchor.constraint(equalTo: centerXAnchor)])
  }
}
