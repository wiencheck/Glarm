//
//  UIColor.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 08/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit

extension UIColor {
    class var tint: UIColor {
        return UIColor(named: "Tint")!
    }
    
    class var background: UIColor {
        if #available(iOS 13.0, *) {
            return .systemBackground
        }
        return .white
    }
    
    class func label() -> UIColor {
        if #available(iOS 13.0, *) {
            return .label
        }
        return .black
    }
    
    class func secondaryLabel() -> UIColor {
        if #available(iOS 13.0, *) {
            return .secondaryLabel
        }
        return .lightGray
    }
}
