//
//  Date.swift
//  Glarm
//
//  Created by Adam Wienconek on 13/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import Foundation

extension Date {
    static func daysBetween(start: Date, end: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: start, to: end).day!
    }
    
    func daysBetween(end: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: self, to: end).day!
    }
    
    static func secondsBetween(start: Date, end: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: start, to: end).second!
    }
    
    var timeDescription: String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: self)
        let minutes = calendar.component(.minute, from: self)
        return "\(hour):\(minutes)"
    }
}
