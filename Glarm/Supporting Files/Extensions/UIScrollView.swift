//
//  UIScrollView.swift
//  Glarm
//
//  Created by Adam Wienconek on 19/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit

extension UIScrollView {
    func startObservingKeyboard() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { [weak self] notification in
            guard let self = self,
                let info = notification.userInfo, let value = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
                return
            }
            let converted = self.convert(value.cgRectValue, from: nil)
            let corrected = CGRect(origin: converted.origin, size: CGSize(width: converted.width, height: converted.height - self.safeAreaInsets.bottom))
            self.keyboardWillAppear(in: corrected)
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) { [weak self] _ in
            self?.keyboardWillDisappear()
        }
    }
    
    func endObservingKeyboard() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func keyboardWillAppear(in frame: CGRect) {
        contentInset.bottom = frame.height
        if #available(iOS 11.1, *) {
            verticalScrollIndicatorInsets.bottom = frame.height
        } else {
            scrollIndicatorInsets.bottom = frame.height
        }
    }
    
    internal func keyboardWillDisappear() {
        contentInset.bottom = 0
        if #available(iOS 11.1, *) {
            verticalScrollIndicatorInsets.bottom = 0
        } else {
            scrollIndicatorInsets.bottom = 0
        }
    }
}
