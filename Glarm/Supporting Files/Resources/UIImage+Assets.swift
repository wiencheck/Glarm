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
    class var folder: UIImage {
        if #available(iOS 13.0, *) {
            return UIImage(systemName: "folder")!
        } else {
            return UIImage(named: "Folder")!
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
    
    static let notificationThumbnailAssetName = "Notification_Thumbnail"

    static let notificationThumbnail = UIImage(named: notificationThumbnailAssetName)!
}

extension UIImage {
    class func createLocalUrl(forAssetNamed name: String) -> URL? {
        
        let fileManager = FileManager.default
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let url = cacheDirectory.appendingPathComponent("\(name).png", isDirectory: false)
        
        guard fileManager.fileExists(atPath: url.path) else {
            guard let image = UIImage(named: name),
                let data = image.pngData()
                else { return nil }
            
            fileManager.createFile(atPath: url.path, contents: data, attributes: nil)
            return url
        }
        
        return url
    }
}
