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
    
    static let `default` = LocationNotificationInfo()
}

extension LocationNotificationInfo: Equatable {}

class AlarmEntry: Codable {
    let identifier: String
    var locationInfo: LocationNotificationInfo
    var sound: Sound
    var date: Date
    var note: String
    
    var isMarked = false
    
    var isActive = false
    
    init(info: LocationNotificationInfo, sound: Sound, note: String) {
        identifier = UUID().uuidString
        locationInfo = info
        self.sound = sound
        date = Date()
        self.note = note
    }
    
    convenience init() {
        self.init(info: LocationNotificationInfo(), sound: .default, note: "")
    }
}

extension AlarmEntry {
    enum CodingKeys: String, CodingKey {
        case identifier
        case locationInfo
        case sound
        case date
        case note
        case isMarked
    }
}

extension AlarmEntry: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

extension AlarmEntry: Equatable {
    static func == (lhs: AlarmEntry, rhs: AlarmEntry) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
