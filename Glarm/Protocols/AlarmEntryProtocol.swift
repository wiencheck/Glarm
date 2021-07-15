//
//  AlarmEntryProtocol.swift
//  Glarm
//
//  Created by Adam Wienconek on 23/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import Foundation
import CoreLocation

protocol AlarmEntryProtocol: SimpleAlarmEntryProtocol {
    /// Name of the audio file to be played alongside the alarm.
    var soundName: String { get set }
    
    /// Value indicating whether user has marked the alarm.
    var isMarked: Bool { get set }
    
    /// Category assigned to the alarm.
    var category: Category? { get set }
    
    /// Value indicating whether alarm is delivered every time user enters a region.
    var isRecurring: Bool { get set }
    
    /// Value indicating whether alarm is currently scheduled and waiting to be fired.
    var isActive: Bool { get }
    
    /// Value indicating whether alarm was saved to the database.
    var isSaved: Bool { get }
}

extension AlarmEntryProtocol {
    func makeSimplified() -> SimpleAlarmEntry {
        return SimpleAlarmEntry(uid: uid,
                                dateCreated: dateCreated,
                                locationInfo: locationInfo,
                                note: note)
    }
}
