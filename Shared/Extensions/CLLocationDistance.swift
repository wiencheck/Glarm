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
        formatter.minimumFractionDigits = 0
        
        switch Locale.preferredUnitLength {
        case .miles:
            formatter.maximumFractionDigits = 1
            guard let representation = formatter.string(from: self.in(.miles) as NSNumber) else {
                return "n/a"
            }
            if usingSpaces {
                return representation + " mi"
            }
            return representation + "mi"
            default:
                if self < 1000 {
                    formatter.maximumFractionDigits = 0
                    guard let representation = formatter.string(from: self as NSNumber) else {
                        return "n/a"
                    }
                    if usingSpaces {
                        return representation + " m"
                    }
                    return representation + "m"
                } else {
                    formatter.maximumFractionDigits = 1
                    guard let representation = formatter.string(from: self/1000 as NSNumber) else {
                        return "n/a"
                    }
                    if usingSpaces {
                        return representation + " km"
                    }
                    return representation + "km"
                }
        }
    }
        
    func convert(from originalUnit: UnitLength, to convertedUnit: UnitLength) -> Double {
      return Measurement(value: self, unit: originalUnit).converted(to: convertedUnit).value
    }
    
    func `in`(_ unit: UnitLength) -> CLLocationDistance {
        return convert(from: .meters, to: unit)
    }
}
