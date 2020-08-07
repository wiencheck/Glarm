//
//  StrippedAlarmEntry.swift
//  Glarm
//
//  Created by Adam Wienconek on 05/08/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import Foundation
import CoreLocation

class SimplifiedAlarmEntry: Codable {
    let identifier: String
    var locationInfo: LocationNotificationInfo
    var note: String
    
    internal init(identifier: String, info: LocationNotificationInfo, note: String) {
        self.identifier = identifier
        locationInfo = info
        self.note = note
    }
    
    init(info: LocationNotificationInfo, note: String) {
        self.identifier = UUID().uuidString
        locationInfo = info
        self.note = note
    }
}
