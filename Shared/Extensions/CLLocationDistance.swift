//
//  Double.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 07/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import CoreLocation

extension CLLocationDistance {
    
    func readableRepresentation(usingSpaces: Bool = false) -> String {
        let formatter: NumberFormatter = .cached()
        
        var unit = UserDefaults.appGroupSuite.preferredUnitLength
        let one = Measurement(value: 1, unit: unit)
            .converted(to: .meters)
            .value

        var value = converted(toUnit: unit)
        if self < one {
            switch unit {
            case .kilometers:
                value *= 1000
                unit = .meters
            case .miles:
                value *= 5280
                unit = .feet
            default:
                break
            }
            formatter.maximumFractionDigits = 0
        } else {
            formatter.maximumFractionDigits = 1
        }
        
        guard var representation = formatter.string(from: value as NSNumber) else {
            return "n/a"
        }
        if usingSpaces {
            representation += " "
        }
        return representation + unit.symbol
    }
    
    func converted(toUnit unit: UnitLength) -> Double {
        return Measurement(value: self, unit: UnitLength.meters).converted(to: unit).value
    }
}
