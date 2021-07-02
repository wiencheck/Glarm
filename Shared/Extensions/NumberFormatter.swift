//
//  DateFormatter.swift
//  Glarm
//
//  Created by Adam Wienconek on 29/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import Foundation

extension NumberFormatter {
    private static var _cached: NumberFormatter?
    
    class func cached() -> NumberFormatter {
        if let _cached = _cached {
            return _cached
        }
        _cached = NumberFormatter()
        return _cached!
    }
}
