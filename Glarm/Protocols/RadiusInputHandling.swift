//
//  RadiusInputHandling.swift
//  Glarm
//
//  Created by Adam Wienconek on 19/07/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import Foundation

protocol RadiusInputHandling {}

extension RadiusInputHandling {
    private static var cachedFormatter: NumberFormatter {
        let cache = NSCache<NSString, NumberFormatter>()
        if let cached = cache.object(forKey: "_formatter") {
            return cached
        }
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        cache.setObject(formatter, forKey: "_formatter")
        return formatter
    }
    
    func translateInputToRadius(_ input: String, unit: UnitLength) -> Double? {
        
        guard let number = Self.cachedFormatter.number(from: input) else {
            return nil
        }
        let measurement = Measurement(value: number.doubleValue, unit: unit)
        let meters = measurement.converted(to: .meters).value
        
        return meters
    }
}
