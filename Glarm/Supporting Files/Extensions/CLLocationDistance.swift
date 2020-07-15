//
//  Double.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 07/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import CoreLocation

extension CLLocationDistance {
    var readableRepresentation: String {
        if Locale.current.usesMetricSystem {
            // Meters
            if self < 1000 {
                return String(format: "%.0f m", self)
            } else {
                let format = self.remainder(dividingBy: 1000) == 0 ? "%.0f km" : "%.1f km"
                let kms = String(format: format, self / 1000)
                return kms
            }
        } else {
            // Miles
            let yards = self * 1.0936
            if yards < 1760 {
                return String(format: "%.0f yd", yards)
            } else {
                let format = self.remainder(dividingBy: 1760) == 0 ? "%.0f mi" : "%.1f mi"
                let mis = String(format: format, yards / 1760)
                return mis
            }
        }
    }
    
    static var `default`: CLLocationDistance = 20 * 1000
}
