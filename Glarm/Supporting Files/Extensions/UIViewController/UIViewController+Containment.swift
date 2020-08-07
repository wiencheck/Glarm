//
//  UIViewController+Containment.swift
//  Glarm
//
//  Created by Adam Wienconek on 06/08/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit

extension UIViewController {
    func add(child controller: UIViewController, superview: UIView? = nil, duration: TimeInterval = 0, completion: ((Bool) -> Void)? = nil) {
        
        controller.willMove(toParent: self)
        addChild(controller)
        controller.view.alpha = 0
        (superview ?? view).addSubview(controller.view)
        controller.view.pinToSuperView()
        
        UIView.animate(withDuration: duration, animations: {
            controller.view.alpha = 1
        }) { finished in
            controller.didMove(toParent: self)
            completion?(finished)
        }
    }
    
    func removeFromParent(duration: TimeInterval = 0, completion: ((Bool) -> Void)? = nil) {
        willMove(toParent: nil)
        UIView.animate(withDuration: duration, animations: {
            self.view.alpha = 0
        }) { finished in
            self.view.removeFromSuperview()
            self.removeFromParent()
            completion?(finished)
        }
    }
}
