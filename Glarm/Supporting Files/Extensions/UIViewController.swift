//
//  UIViewController.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 06/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit

@objc extension UIViewController {
    func add(child controller: UIViewController, superview: UIView? = nil, duration: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        
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
    
    func removeFromParent(duration: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        willMove(toParent: nil)
        UIView.animate(withDuration: duration, animations: {
            self.view.alpha = 0
        }) { finished in
            self.view.removeFromSuperview()
            self.removeFromParent()
            completion?(finished)
        }
    }
    
    func displayErrorMessage(title: String?, error: Error?) {
        let alert = AWAlertController(title: title ?? LocalizedStringKey.errorOccurred.localized, message: error?.localizedDescription ?? LocalizedStringKey.errorUnknown.localized, preferredStyle: .alert)
        alert.addAction(.cancel(text: LocalizedStringKey.dismiss.localized))
        present(alert, animated: true, completion: nil)
    }
}
