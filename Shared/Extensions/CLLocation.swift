//
//  CLLocation.swift
//  Glarm
//
//  Created by Adam Wienconek on 14/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import MapKit

extension CLLocation {
    convenience init(coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    class var cupertinoUser: CLLocation {
        CLLocation(coordinate: .cupertinoUser,
                                  altitude: 69,
                                  horizontalAccuracy: .infinity,
                                  verticalAccuracy: .infinity,
                                  course: .infinity,
                                  speed: 54.7,
                                  timestamp: Date())
    }
}
