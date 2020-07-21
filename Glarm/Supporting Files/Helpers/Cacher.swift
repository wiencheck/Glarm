//
//  GlobalCache.swift
//  Plum
//
//  Created by Adam Wienconek on 30/06/2020.
//  Copyright © 2020 adam.wienconek. All rights reserved.
//

import Foundation

final class Cacher {
    private static let cache = NSCache<NSString, AnyObject>()
    
    class func object(key: String) -> AnyObject? {
        return cache.object(forKey: key as NSString)
    }
    
    class func set(object: AnyObject?, at key: String) {
        if let object = object {
            cache.setObject(object, forKey: key as NSString)
        } else {
            cache.removeObject(forKey: key as NSString)
        }
    }
}
