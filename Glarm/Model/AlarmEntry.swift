//
//  AlarmEntry.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 06/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import CoreLocation
import MapKit

struct LocationNotificationInfo: Codable {
    
    var identifier: String
    var coordinate: CLLocationCoordinate2D
    var radius: CLLocationDistance
    
    init(identifier: String, coordinate: CLLocationCoordinate2D, radius: CLLocationDistance) {
        self.identifier = identifier
        self.coordinate = coordinate
        self.radius = radius
    }
    
    init() {
        self.init(identifier: "", coordinate: .zero, radius: .default)
    }
    
    static let `default` = LocationNotificationInfo()
}

extension LocationNotificationInfo: Equatable {}

class AlarmEntry: Codable {
    let identifier: String
    var locationInfo: LocationNotificationInfo
    var tone: AlarmTone
    var date: Date
    var isMarked = false
    
    var isActive = false
    
    init(info: LocationNotificationInfo, tone: AlarmTone) {
        identifier = UUID().uuidString
        locationInfo = info
        self.tone = tone
        date = Date()
    }
    
    convenience init() {
        self.init(info: LocationNotificationInfo(), tone: .default)
    }
}

extension AlarmEntry {
    enum CodingKeys: String, CodingKey {
        case identifier
        case locationInfo
        case tone
        case date
        case isMarked
    }
}

extension AlarmEntry: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
        //hasher.combine(date)
    }
}

extension AlarmEntry: Equatable {
    static func == (lhs: AlarmEntry, rhs: AlarmEntry) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
