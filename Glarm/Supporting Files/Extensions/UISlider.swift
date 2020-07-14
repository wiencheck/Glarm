//
//  UISlider.swift
//  Musico
//
//  Created by adam.wienconek on 23.10.2018.
//  Copyright © 2018 adam.wienconek. All rights reserved.
//

import UIKit

extension UISlider {
    public func addTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }
    
    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: self)
        let percent = minimumValue + Float(location.x / bounds.width) * maximumValue
        setValue(percent, animated: true)
        sendActions(for: .valueChanged)
    }
    
    struct AssociatedKeys {
        static var slideHandler: UInt8 = 0
    }
    
    typealias UISliderAction = ((UISlider) -> Void)
    
    var slideHandler: UISliderAction? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.slideHandler) as? UISliderAction
        } set {
            objc_setAssociatedObject(self, &AssociatedKeys.slideHandler, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            if newValue == nil {
                removeTarget(self, action: #selector(_handleSlide), for: .valueChanged)
            } else {
                addTarget(self, action: #selector(_handleSlide), for: .valueChanged)
            }
        }
    }
    
    @objc private func _handleSlide() {
        slideHandler?(self)
    }
}
