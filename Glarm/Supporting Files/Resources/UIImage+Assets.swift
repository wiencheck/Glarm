//
//  UIImage+Assets.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 06/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit

extension UIImage {
    static let disclosure = UIImage(named: "Disclosure")!
    static let star = UIImage(named: "Star")!
    class var info: UIImage {
        if #available(iOS 13.0, *) {
            return UIImage(systemName: "info.circle")!
        } else {
            return UIImage(named: "Info")!
        }
    }
    static let glarm = UIImage(named: "Glarm")!
    
    class var download: UIImage {
        if #available(iOS 13.0, *) {
            return UIImage(systemName: "arrow.down.circle")!
        } else {
            return UIImage(named: "Download")!
        }
    }
}
