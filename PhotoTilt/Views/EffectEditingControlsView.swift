//
//  EffectEditingControlsView.swift
//  PhotoTilt
//
//  Created by Zaid Elkurdi on 2/26/18.
//  Copyright © 2018 Zaid Elkurdi. All rights reserved.
//

import UIKit

class EffectEditingControlsView: UIView, UIGestureRecognizerDelegate {
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

  let blurSlider = UISlider()
  private let blurSliderLabel = sliderLabel(for: "Blur")
  
  private let stackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.spacing = 3.0
    return stackView
  }()

  fileprivate lazy var panGestureRecognizer: UIPanGestureRecognizer = {
    let panGestureRecognizer = UIPanGestureRecognizer()
    panGestureRecognizer.addTarget(self, action: #selector(didPan))
    panGestureRecognizer.delegate = self
    return panGestureRecognizer
  }()

  private var handlebarView = HandlebarView()
  
  init(initialSlope: Float, initialWidth: Float) {
    super.init(frame: .zero)
    slopeSlider.minimumValue = 0.1
    slopeSlider.maximumValue = 10.0
    slopeSlider.value = initialSlope

    blurSlider.minimumValue = 0.0
    blurSlider.maximumValue = 30.0
    
    widthSlider.value = initialWidth
    
    stackView.addArrangedSubviews([focusSliderLabel, focusSlider, slopeSliderLabel, slopeSlider, widthSliderLabel, widthSlider, blurSliderLabel, blurSlider])
    addSubviews([backgroundView, stackView, handlebarView])
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
      "blurSliderLabel": blurSliderLabel,
      "blurSlider": blurSlider,
      "handlebarView": handlebarView
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

    let constraints = [
      handlebarView.bottomAnchor.constraint(equalTo: backgroundView.topAnchor, constant: -5),
      handlebarView.centerXAnchor.constraint(equalTo: centerXAnchor)
    ]

    NSLayoutConstraint.activate(constraints)
  }
  
  static func sliderLabel(for name: String) -> UILabel {
    let label = UILabel()
    label.textColor = .white
    label.text = name
    return label
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    if gestureRecognizer === panGestureRecognizer {
      // Pan gesture should be recognized if the touch starts inside bottomModalView or near the handle bar
      let touchLocation = touch.location(in: self)
      let expandedHandlebarViewFrame = convert(handlebarView.bounds, from: handlebarView).applying(CGAffineTransform.init(scaleX: 2.0, y: 2.0))
      return expandedHandlebarViewFrame.contains(touchLocation)
    }
    return false
  }
  @objc func didPan(gestureRecognizer: UIPanGestureRecognizer) {
//    switch gestureRecognizer.state {
//    case .changed:
//      callback(.didPan(translation: gestureRecognizer.translation(in: superview).y))
//      // We reset the translation so that we only look at deltas between didPan calls and not the overall gesture translation
//      gestureRecognizer.setTranslation(.zero, in: superview)
//    case .ended, .failed, .cancelled:
//      callback(.didEndPan(velocity: gestureRecognizer.velocity(in: superview).y))
//    default:
//      return
//    }
  }
}

class HandlebarView: UIView {
  init() {
    super.init(frame: .zero)
    layer.cornerRadius = 2.5
    backgroundColor = UIColor.gray
  }

  required init(coder: NSCoder) { fatalError() }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: 60, height: 5)
  }
}
