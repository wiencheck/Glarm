//
//  Date.swift
//  Glarm
//
//  Created by Adam Wienconek on 13/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import Foundation

extension Date {
    public static func daysBetween(start: Date, end: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: start, to: end).day!
    }
    
    public func daysBetween(end: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: self, to: end).day!
    }
    
    public static func secondsBetween(start: Date, end: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: start, to: end).second!
    }
}
