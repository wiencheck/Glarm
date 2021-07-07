//
//  LocationNotificationInfo.swift
//  Glarm
//
//  Created by Adam Wienconek on 30/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import CoreLocation

struct LocationNotificationInfo: Codable {
    var name: String
    var coordinate: CLLocationCoordinate2D
    var radius: CLLocationDistance
    
    init(name: String, coordinate: CLLocationCoordinate2D, radius: CLLocationDistance) {
        self.name = name
        self.coordinate = coordinate
        self.radius = radius
    }
    
    init() {
        self.init(name: "", coordinate: .zero, radius: .default)
    }
    
    var location: CLLocation { .init(coordinate: coordinate) }
    
    static let `default` = LocationNotificationInfo()
}

extension LocationNotificationInfo: Equatable {}

extension CLLocationDistance {
    static var `default`: CLLocationDistance = 20 * 1000
}
