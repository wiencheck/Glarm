//
//  PlistReader.swift
//  Plum
//
//  Created by adam.wienconek on 13.12.2018.
//  Copyright © 2018 adam.wienconek. All rights reserved.
//

import Foundation

/// Utility class for getting contents of property list files
class PlistReader {
    class func dictionary(from file: String) -> [String: Any]? {
        if let path = Bundle.main.path(forResource: file, ofType: "plist") {
            return NSDictionary(contentsOfFile: path) as? [String: Any]
        } else {
            print("*** Couldn't create Dictionary from \(file).plist")
            return nil
        }
    }
    
    class func property(from file: String, key: String) -> Any? {
        return dictionary(from: file)?[key]
    }
}
