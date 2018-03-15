//
//  EditingView.swift
//  PhotoTilt
//
//  Created by Zaid Elkurdi on 2/25/18.
//  Copyright © 2018 Zaid Elkurdi. All rights reserved.
//

import UIKit

class EditingView: UIView {
  let videoPreviewView = UIView()
  let toggleButton = UIButton()
  
  let depthEditingControlsView = DepthEditingControlsView(initialNoise: 0.02, initialSharpness: 0.40)
  let effectEditingControlsView = EffectEditingControlsView(initialSlope: 4.0, initialWidth: 0.1)
 
  var playerLayer: CALayer?
  
  private let onVideoSourceToggled: (Bool) -> Void
  private var showingVideo = true
  
  init(onVideoSourceToggled: @escaping (Bool) -> Void) {
    self.onVideoSourceToggled = onVideoSourceToggled
    super.init(frame: .zero)
    depthEditingControlsView.isHidden = true
    videoPreviewView.backgroundColor = .white
    toggleButton.backgroundColor = .black
    toggleButton.setTitle("Show Depth Data", for: .normal)
    toggleButton.addTarget(self, action: #selector(toggleVideoSource), for: .touchUpInside)
    addSubviews([videoPreviewView, effectEditingControlsView, depthEditingControlsView, toggleButton])
    installConstraints()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSublayers(of layer: CALayer) {
    super.layoutSublayers(of: layer)
    playerLayer?.frame = videoPreviewView.bounds
  }
  
  @objc private func toggleVideoSource() {
    showingVideo = !showingVideo
    toggleButton.setTitle(showingVideo ? "Show Depth Data" : "Show Video", for: .normal)
    onVideoSourceToggled(showingVideo)
  }
  
  private func installConstraints() {
    let views = [
      "toggleButton": toggleButton,
      "videoPreviewView": videoPreviewView,
      "depthEditingControlsView": depthEditingControlsView,
      "effectEditingControlsView": effectEditingControlsView,
      ]
    
    let metrics = [
      "captureButtonSize": 80
    ]
    
    views.values.forEach({ $0.translatesAutoresizingMaskIntoConstraints = false })
    
    NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormats: [
      "H:|[videoPreviewView]|",
      "H:[toggleButton]|",
      "V:|-90-[toggleButton]",
      "V:|-90-[videoPreviewView]-150-|",
      "V:[depthEditingControlsView]|",
      "H:|-30-[depthEditingControlsView]-30-|",
      "V:[effectEditingControlsView]|",
      "H:|-30-[effectEditingControlsView]-30-|"
      ], metrics: metrics, views: views))
  }
}
