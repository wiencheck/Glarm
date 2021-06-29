//
//  AlarmEntryProtocol.swift
//  Glarm
//
//  Created by Adam Wienconek on 23/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import Foundation
import CoreLocation

protocol AlarmEntryProtocol {
    /// Unique identifier of the alarm.
    var uid: String { get }
    
    /// Date when alarm was created/scheduled.
    var dateCreated: Date { get set }
    
    /// Object holding information about location and radius of the alarm.
    var locationInfo: LocationNotificationInfo? { get set }
    
    /// User-defined note attached to the alarm.
    var note: String { get set }
    
    /// Name of the audio file to be played alongside the alarm.
    var soundName: String { get set }
    
    /// Value indicating whether user has marked the alarm.
    var isMarked: Bool { get set }
    
    /// Category assigned to the alarm.
    var category: Category? { get set }
    
    /// Value indicating whether alarm is currently scheduled and waiting to be fired.
    var isActive: Bool { get }
    
    /// Value indicating whether alarm was saved to the database.
    var isSaved: Bool { get }
}
