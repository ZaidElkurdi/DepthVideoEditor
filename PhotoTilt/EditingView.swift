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
  let widthSliderLabel: UILabel = {
    let label = UILabel()
    label.textColor = .white
    label.text = "Width"
    return label
  }()
  let widthSlider = UISlider()
  let slopeSliderLabel: UILabel = {
    let label = UILabel()
    label.textColor = .white
    label.text = "Slope"
    return label
  }()
  let slopeSlider = UISlider()
  let focusSliderLabel: UILabel = {
    let label = UILabel()
    label.textColor = .white
    label.text = "Focus"
    return label
  }()
  let focusSlider = RangeSeekSlider()
  var playerLayer: CALayer?
  
  init() {
    super.init(frame: .zero)
    focusSlider.tintColor = nil
    addSubviews([videoPreviewView, focusSliderLabel, focusSlider, widthSliderLabel, widthSlider, slopeSliderLabel, slopeSlider])
    installConstraints()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSublayers(of layer: CALayer) {
    super.layoutSublayers(of: layer)
    playerLayer?.frame = videoPreviewView.bounds
  }
  
  private func installConstraints() {
    let views = [
      "videoPreviewView": videoPreviewView,
      "widthSliderLabel": widthSliderLabel,
      "widthSlider": widthSlider,
      "slopeSliderLabel": slopeSliderLabel,
      "slopeSlider": slopeSlider,
      "focusSliderLabel": focusSliderLabel,
      "focusSlider": focusSlider,
      ]
    
    let metrics = [
      "captureButtonSize": 80
    ]
    
    views.values.forEach({ $0.translatesAutoresizingMaskIntoConstraints = false })
    
    NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormats: [
      "H:|[videoPreviewView]|",
      "H:|-30-[widthSliderLabel]",
      "H:|-30-[slopeSliderLabel]",
      "H:|-30-[focusSliderLabel]",
      "H:|-30-[widthSlider]-30-|",
      "H:|-30-[slopeSlider]-30-|",
      "H:|-30-[focusSlider]-30-|",
      "V:[slopeSliderLabel][slopeSlider]-10-[widthSliderLabel][widthSlider]-10-[focusSliderLabel][focusSlider]-50-|",
      "V:|[videoPreviewView]-150-|",
      ], metrics: metrics, views: views))
  }
}
