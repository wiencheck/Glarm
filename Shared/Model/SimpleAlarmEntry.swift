//
//  SimpleAlarmEntry.swift
//  Glarm
//
//  Created by Adam Wienconek on 30/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import Foundation

struct SimpleAlarmEntry: SimpleAlarmEntryProtocol, Codable {
    let uid: String
    
    var dateCreated: Date
    
    var locationInfo: LocationNotificationInfo?
    
    var note: String
    
    init(uid: String = UUID().uuidString, dateCreated: Date = Date(), locationInfo: LocationNotificationInfo? = nil, note: String) {
        self.uid = uid
        self.dateCreated = dateCreated
        self.locationInfo = locationInfo
        self.note = note
    }
}
