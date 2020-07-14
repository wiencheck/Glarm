//
//  UIButton.swift
//  Musico
//
//  Created by Adam Wienconek on 07.10.2018.
//  Copyright © 2018 adam.wienconek. All rights reserved.
//

import UIKit

extension UIButton {
    
    struct AssociatedKeys {
        static var pressHandler: UInt8 = 0
    }
    
    var pressHandler: ((UIButton) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.pressHandler) as? ((UIButton) -> Void)
        } set {
            objc_setAssociatedObject(self, &AssociatedKeys.pressHandler, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            if newValue == nil {
                removeTarget(self, action: #selector(touchUp), for: .touchUpInside)
            } else {
                addTarget(self, action: #selector(touchUp), for: .touchUpInside)
            }
        }
    }
    
    @objc private func touchUp() {
        pressHandler?(self)
    }
    
    var text: String? {
        get {
            return title(for: .normal)
        } set {
            setTitle(newValue, for: .normal)
        }
    }
    
    var image: UIImage? {
        get {
            return image(for: .normal)
        } set {
            setImage(newValue, for: .normal)
        }
    }
    
    var textColor: UIColor? {
        get {
            return titleColor(for: .normal)
        } set {
            setTitleColor(newValue, for: .normal)
        }
    }
    
    @IBInspectable var imageContentMode: UIView.ContentMode {
        get {
            return imageView?.contentMode ?? .scaleToFill
        } set {
            imageView?.contentMode = newValue
        }
    }
    
    func setImageAnimated(_ image: UIImage?, for state: UIControl.State = .normal, duration: TimeInterval = 0.3, options: UIView.AnimationOptions = [.transitionCrossDissolve, .curveLinear], completion: ((Bool) -> Void)? = nil) {
        UIView.transition(with: self, duration: duration, options: options, animations: {
            self.setImage(image, for: state)
        }, completion: completion)
    }
    
    func setBackgroundImageAnimated(_ image: UIImage?, for state: UIControl.State, duration: TimeInterval = 0.3, options: UIView.AnimationOptions = [.transitionCrossDissolve, .curveLinear], completion: ((Bool) -> Void)? = nil) {
        UIView.transition(with: self, duration: duration, options: options, animations: {
            self.setBackgroundImage(image, for: .normal)
        }, completion: completion)
    }
    
    private func image(withColor color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func setBackgroundColor(_ color: UIColor?, for state: UIControl.State) {
        self.setBackgroundImage(image(withColor: color ?? .clear), for: state)
    }
    
    func setBackgroundView(_ backgroundView: UIView) {
        insertSubview(backgroundView, aboveSubview: self)
    }
    
}
