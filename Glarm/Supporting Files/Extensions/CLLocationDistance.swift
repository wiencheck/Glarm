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
        if self < 1000 {
            return String(format: "%.0f m", self)
        } else {
            let format = self.remainder(dividingBy: 1000) == 0 ? "%.0f km" : "%.1f km"
            let kms = String(format: format, self / 1000)
            return kms
        }
    }
    
    static let `default`: CLLocationDistance = 20000
}
