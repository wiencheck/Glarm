//
//  Locale.swift
//  Glarm
//
//  Created by Adam Wienconek on 20/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import Foundation

extension Locale {
    static var preferred: Locale {
        if let preferredIdentifier = Locale.preferredLanguages.first {
            return Locale(identifier: preferredIdentifier)
        } else {
            return .current
        }
    }
    
    static var preferredUnitLength: UnitLength {
        get {
            guard let symbol = UserDefaults.standard.string(forKey: "preferredUnitLength") else {
                return .meters
            }
            switch symbol {
            case "m":
                return .meters
            case "mi":
                return .miles
            default:
                return UnitLength(symbol: symbol)
            }
        } set {
            UserDefaults.standard.set(newValue.symbol, forKey: "preferredUnitLength")
        }
    }
}
