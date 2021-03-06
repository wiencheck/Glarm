//
//  UIAlertAction.swift
//  Glarm
//
//  Created by Adam Wienconek on 13/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit

extension UIAlertAction {
    convenience init(localizedTitle: LocalizedStringKey, style: UIAlertAction.Style, handler: ((UIAlertAction) -> Void)? = nil) {
        self.init(title: localizedTitle.localized, style: style, handler: handler)
    }
    
    class func cancel(text: String, action: (() -> Void)? = nil) -> UIAlertAction {
        return UIAlertAction(title: text, style: .cancel) { _ in
            action?()
        }
    }
    
    class func cancel(localizedText: LocalizedStringKey = .cancel, action: (() -> Void)? = nil) -> UIAlertAction {
        return cancel(text: localizedText.localized, action: action)
    }
    
    class var dismiss: UIAlertAction {
        return .cancel(text: LocalizedStringKey.dismiss.localized)
    }
}
