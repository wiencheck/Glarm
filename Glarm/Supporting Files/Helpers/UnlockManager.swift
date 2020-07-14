//
//  UnlockManager.swift
//  Glarm
//
//  Created by Adam Wienconek on 13/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import Foundation

class UnlockManager {
    class var unlocked: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "unlocked")
        } set {
            UserDefaults.standard.set(newValue, forKey: "unlocked")
        }
    }
    
    private class var alarmDates: [Date] {
        get {
            return UserDefaults.standard.array(forKey: "alarmDates") as? [Date] ?? []
        } set {
            UserDefaults.standard.set(newValue, forKey: "alarmDates")
        }
    }
    
    class func canScheduleAlarm() -> Bool {
        guard let first = alarmDates.min(), first.daysBetween(end: Date()) >= 7 else {
            return false
        }
        return true
    }
    
    class func saveAlarmDate() {
        let updated = alarmDates + [Date()]
        alarmDates = updated.suffix(3)
    }
}
