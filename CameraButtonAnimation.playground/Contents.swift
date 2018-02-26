//: A UIKit based Playground for presenting user interface

import UIKit
import PlaygroundSupport

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

class CaptureButton: UIControl {
  private let centerShape: UIView = {
    let view = UIView()
    view.backgroundColor = .red
    return view
  }()
  private var isActive = false
  private let onTap: (Bool) -> Void
  private let outlineCircle: UIView = {
    let view = UIView()
    view.layer.borderColor = UIColor.white.cgColor
    view.backgroundColor = .clear
    return view
  }()
  
  init(onTap: @escaping (Bool) -> Void) {
    self.onTap = onTap
    
    super.init(frame: .zero)

    addSubviews([outlineCircle, centerShape])
    
    outlineCircle.translatesAutoresizingMaskIntoConstraints = false
    centerShape.translatesAutoresizingMaskIntoConstraints = false
    let constraints = [
      outlineCircle.centerXAnchor.constraint(equalTo: centerXAnchor),
      outlineCircle.centerYAnchor.constraint(equalTo: centerYAnchor),
      outlineCircle.widthAnchor.constraint(equalTo: widthAnchor),
      outlineCircle.heightAnchor.constraint(equalTo: heightAnchor),
      centerShape.centerXAnchor.constraint(equalTo: centerXAnchor),
      centerShape.centerYAnchor.constraint(equalTo: centerYAnchor),
      centerShape.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7),
      centerShape.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.7)
    ]
    NSLayoutConstraint.activate(constraints)
    setActive(false, animated: false)
  }
  
  func setActive(_ active: Bool, animated: Bool) {
    isActive = active
    UIView.animate(withDuration: animated ? 0.5 : 0.0, animations: { [weak self] in
      guard let `self` = self else { return }
      let scale: CGFloat = active ? 0.7 : 1.0
      let scaleTransform = CGAffineTransform.init(scaleX: scale, y: scale)
      
//      let rotation: CGFloat = active ? .pi / 2.0 : -(.pi / 2.0)
//      let rotationTransfom = CGAffineTransform.init(rotationAngle: rotation)
      self.centerShape.transform = scaleTransform//.concatenating(rotationTransfom)
      self.centerShape.layer.cornerRadius = self.isActive ? self.centerShape.frame.width / 5.0 : self.centerShape.frame.width / 2.0
    })
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    outlineCircle.layer.borderWidth = outlineCircle.frame.width / 10.0
    outlineCircle.layer.cornerRadius = outlineCircle.frame.width / 2.0
    centerShape.layer.cornerRadius = isActive ? centerShape.frame.width / 5.0 : centerShape.frame.width / 2.0
  }
}

let view = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 375.0, height: 667.0))
view.backgroundColor = .black
PlaygroundPage.current.liveView = view

let captureButton = CaptureButton(onTap: { _ in })
captureButton.frame = CGRect(x: 100, y: 100, width: 50, height: 50)
view.addSubview(captureButton)

//DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
  captureButton.setActive(true, animated: true)
//}

//view.addSubview(centerShape)
//view.layer.addSublayer(outlineLayer)
//
//UIView.animate(withDuration: 0.5, animations: { () -> Void in
//  let scaleTransform = CGAffineTransform.init(scaleX: 0.6, y: 0.6)
//  let rotationTransfom = CGAffineTransform.init(rotationAngle: .pi / 2.0)
//  centerShape.transform = scaleTransform.concatenating(rotationTransfom)
//  centerShape.layer.cornerRadius = 10.0
//})

//
//UIView.animate(withDuration: 1.0, delay: 0.5, options: .curveEaseIn, animations: {
//  centerShapeLayer.transform = CATransform3DMakeScale(0.5, 0.5, 0.5)
//  print(shapeLayer.position)
//  print(centerShapeLayer.position)
//  centerShapeLayer.frame.center = shapeLayer.frame.center
//}, completion: nil)

//centerShapeLayer.add(animation, forKey: nil)

