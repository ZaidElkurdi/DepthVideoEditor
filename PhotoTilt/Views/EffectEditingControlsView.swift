//
//  EffectEditingControlsView.swift
//  PhotoTilt
//
//  Created by Zaid Elkurdi on 2/26/18.
//  Copyright © 2018 Zaid Elkurdi. All rights reserved.
//

import UIKit

class EffectEditingControlsView: UIView {
  private let backgroundView: UIView = {
    let view = UIView()
    view.backgroundColor = .black
    view.alpha = 0.6
    view.layer.cornerRadius = 8.0
    return view
  }()
  
  let focusSlider = RangeSeekSlider()
  private let focusSliderLabel = sliderLabel(for: "Focus")
  
  let slopeSlider = UISlider()
  private let slopeSliderLabel = sliderLabel(for: "Slope")
  
  let widthSlider = UISlider()
  private let widthSliderLabel = sliderLabel(for: "Width")
  
  private let stackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.spacing = 3.0
    return stackView
  }()
  
  init(initialSlope: Float, initialWidth: Float) {
    super.init(frame: .zero)
    slopeSlider.minimumValue = 0.1
    slopeSlider.maximumValue = 10.0
    slopeSlider.value = initialSlope
    
    widthSlider.value = initialWidth
    
    stackView.addArrangedSubviews([focusSliderLabel, focusSlider, slopeSliderLabel, slopeSlider, widthSliderLabel, widthSlider])
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
