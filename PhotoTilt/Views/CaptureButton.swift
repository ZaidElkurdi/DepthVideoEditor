//
//  CaptureButton.swift
//  PhotoTilt
//
//  Created by Zaid Elkurdi on 2/10/18.
//  Copyright © 2018 Zaid Elkurdi. All rights reserved.
//

import UIKit

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
  
  convenience init() {
    self.init(onTap: { _ in })
  }
  
  init(onTap: @escaping (Bool) -> Void) {
    self.onTap = onTap
    super.init(frame: .zero)
    addSubviews([outlineCircle, centerShape])
    outlineCircle.isUserInteractionEnabled = false
    centerShape.isUserInteractionEnabled = false
    addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    installConstraints()
    setActive(false, animated: false)
  }
  
  @objc private func buttonTapped() {
    isActive = !isActive
    setActive(isActive, animated: true)
    onTap(isActive)
  }
  
  private func installConstraints() {
    [outlineCircle, centerShape].forEach({ $0.translatesAutoresizingMaskIntoConstraints = false })
    
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
  }
  
  func setActive(_ active: Bool, animated: Bool) {
    isActive = active
    UIView.animate(withDuration: animated ? 0.3 : 0.0, animations: { [weak self] in
      guard let `self` = self else { return }
      let scale: CGFloat = active ? 0.8 : 1.0
      self.centerShape.transform = CGAffineTransform.init(scaleX: scale, y: scale)
      self.centerShape.layer.cornerRadius = self.isActive ? self.centerShape.frame.width / 5.0 : self.centerShape.frame.width / 2.0
    })
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    outlineCircle.layer.borderWidth = outlineCircle.frame.width / 15.0
    outlineCircle.layer.cornerRadius = outlineCircle.frame.width / 2.0
    centerShape.layer.cornerRadius = isActive ? centerShape.frame.width / 5.0 : centerShape.frame.width / 2.0
  }
}
