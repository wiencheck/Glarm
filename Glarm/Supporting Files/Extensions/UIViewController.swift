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
        let alert = AWAlertController(title: title ?? LocalizedStringKey.message_errorOccurred.localized, message: error?.localizedDescription ?? LocalizedStringKey.message_errorUnknown.localized, preferredStyle: .alert)
        alert.addAction(.cancel(text: LocalizedStringKey.dismiss.localized))
        present(alert, animated: true, completion: nil)
    }
}

//
//  UINavigationBarBackButtonHandler.swift
//  Demo
//
//  Created by HamGuy on 20/04/2017.
//  Copyright © 2017 hamguy.net. All rights reserved.
//
import Foundation


/// Handle UINavigationBar's 'Back' button action
protocol  UINavigationBarBackButtonHandler {
    
    /// Should block the 'Back' button action
    ///
    /// - Returns: true - dot block，false - block
    func  shouldPopOnBackButton() -> Bool
}

extension UIViewController: UINavigationBarBackButtonHandler {
    //Do not block the "Back" button action by default, otherwise, override this function in the specified viewcontroller
    @objc func shouldPopOnBackButton() -> Bool {
        return true
    }
}

extension UINavigationController: UINavigationBarDelegate {
    public func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool{
        guard let items = navigationBar.items else {
            return false
        }
        
        if viewControllers.count < items.count {
            return true
        }
        
        var shouldPop = true
        if let vc = topViewController, vc.responds(to: #selector(UIViewController.shouldPopOnBackButton)){
            shouldPop = vc.shouldPopOnBackButton()
        }
        
        if shouldPop{
            DispatchQueue.main.async {
                self.popViewController(animated: true)
            }
        }else{
            for aView in navigationBar.subviews{
                if aView.alpha > 0 && aView.alpha < 1{
                    aView.alpha = 1.0
                }
            }
        }
        return false
    }
}
