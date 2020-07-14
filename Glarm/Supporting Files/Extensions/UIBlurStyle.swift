//
//  UIBlurStyle.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 09/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit

extension UIBlurEffect.Style {
    static var `default`: UIBlurEffect.Style {
        if #available(iOS 13.0, *) {
            return .systemUltraThinMaterial
        } else {
            return .regular
        }
    }
}
