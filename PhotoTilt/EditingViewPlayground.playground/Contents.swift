//: A UIKit based Playground for presenting user interface

import UIKit
import PlaygroundSupport

class EditingView: UIView {
  let videoPreviewView = UIView()
  let widthSlider = UISlider()
  let slopeSlider = UISlider()
  let focusSlider = RangeSeekSlider()
  var playerLayer: CALayer?
  
  init() {
    super.init(frame: .zero)
    [videoPreviewView, focusSlider, widthSlider, slopeSlider].forEach({ addSubview($0) })
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
      "widthSlider": widthSlider,
      "slopeSlider": slopeSlider,
      "focusSlider": focusSlider,
      ]
    
    let metrics = [
      "captureButtonSize": 80
    ]
    
    views.values.forEach({ $0.translatesAutoresizingMaskIntoConstraints = false })
    
    NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormats: [
      "H:|[videoPreviewView]|",
      "H:|-30-[widthSlider]-30-|",
      "H:|-30-[slopeSlider]-30-|",
      "H:|-30-[focusSlider]-30-|",
      "V:[slopeSlider]-10-[widthSlider]-10-[focusSlider]-50-|",
      "V:|[videoPreviewView]-150-|",
      ], metrics: metrics, views: views))
  }
}

let editView = EditingView()

// Present the view controller in the Live View window
PlaygroundPage.current.liveView = editView
