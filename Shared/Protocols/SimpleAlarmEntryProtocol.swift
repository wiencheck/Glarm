//
//  SimpleAlarmEntryProtocol.swift
//  Glarm
//
//  Created by Adam Wienconek on 30/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import Foundation
import CoreLocation

protocol SimpleAlarmEntryProtocol {
    /// Unique identifier of the alarm.
    var uid: String { get }
    
    /// Date when alarm was created/scheduled.
    var dateCreated: Date { get set }
    
    /// Object holding information about location and radius of the alarm.
    var locationInfo: LocationNotificationInfo? { get set }
    
    /// User-defined note attached to the alarm.
    var note: String { get set }
}
