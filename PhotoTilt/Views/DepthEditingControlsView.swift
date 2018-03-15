//
//  DepthEditingControlsView.swift
//  PhotoTilt
//
//  Created by Zaid Elkurdi on 2/26/18.
//  Copyright © 2018 Zaid Elkurdi. All rights reserved.
//

import UIKit

class DepthEditingControlsView: UIView {
  private let backgroundView: UIView = {
    let view = UIView()
    view.backgroundColor = .black
    view.alpha = 0.6
    view.layer.cornerRadius = 8.0
    return view
  }()
  
  var noiseReductionParameters: [String:Any] {
    return ["inputNoiseLevel": noiseSlider.value,
            "inputSharpness": sharpnessSlider.value]
  }
  
  private let noiseSlider = UISlider()
  private let noiseSliderLabel = sliderLabel(for: "Noise")
  
  private let sharpnessSlider = UISlider()
  private let sharpnessSliderLabel = sliderLabel(for: "Sharpness")
  
  private let stackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.spacing = 3.0
    return stackView
  }()
  
  init(initialNoise: Float, initialSharpness: Float) {
    super.init(frame: .zero)
    noiseSlider.minimumValue = 0.0
    noiseSlider.maximumValue = 0.1
    noiseSlider.value = initialNoise
    
    sharpnessSlider.minimumValue = 0.0
    sharpnessSlider.maximumValue = 1.0
    sharpnessSlider.value = initialSharpness
    
    stackView.addArrangedSubviews([noiseSliderLabel, noiseSlider, sharpnessSliderLabel, sharpnessSlider])
    addSubviews([backgroundView, stackView])
    installConstraints()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func installConstraints() {
    let views = [
      "stackView": stackView,
      "backgroundView": backgroundView,
      "sharpnessSliderLabel": sharpnessSliderLabel,
      "sharpnessSlider": sharpnessSlider,
      "noiseSliderLabel": noiseSliderLabel,
      "noiseSlider": noiseSlider,
      ]
    
    let metrics = [
      "captureButtonSize": 80
    ]
    
    views.values.forEach({ $0.translatesAutoresizingMaskIntoConstraints = false })
    
    NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormats: [
      "H:|[backgroundView]|",
      "V:|[backgroundView]|",
      "H:|-30-[stackView]-30-|",
      "V:|-30-[stackView]-30-|",
      ], metrics: metrics, views: views))
  }
  
  static func sliderLabel(for name: String) -> UILabel {
    let label = UILabel()
    label.textColor = .white
    label.text = name
    return label
  }
}

