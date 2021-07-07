//
//  UserDefaults.swift
//  Glarm
//
//  Created by Adam Wienconek on 24/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import Foundation
import CoreLocation

extension UserDefaults {
    class var appGroupSuite: UserDefaults {
        return UserDefaults(suiteName: SharedConstants.appGroupIdentifier)!
    }
    
    private static let recentAlarmsUserDefaultsKey = "recentAlarmsUserDefaultsKey"
    var recentAlarms: [SimpleAlarmEntry]? {
        get {
            guard let arr = array(forKey: Self.recentAlarmsUserDefaultsKey) as? [Data] else {
                return []
            }
            return arr.compactMap { data in
                try? JSONDecoder().decode(SimpleAlarmEntry.self, from: data)
            }
        } set {
            let arr = newValue?.compactMap { entry -> Data? in
                try? JSONEncoder().encode(entry)
            } ?? []
            if arr.isEmpty {
                removeObject(forKey: Self.recentAlarmsUserDefaultsKey)
            } else {
                set(arr, forKey: Self.recentAlarmsUserDefaultsKey)
            }
        }
    }
    
    private static let lastLocationUserDefaultsKey = "lastSpeedUserDefaultsKey"
    var lastLocation: CLLocation? {
        get {
            guard let data = data(forKey: Self.lastLocationUserDefaultsKey) else {
                return nil
            }
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CLLocation.self, from: data)
        } set {
            guard let location = newValue else {
                removeObject(forKey: Self.lastLocationUserDefaultsKey)
                return
            }
            let encoded = try? NSKeyedArchiver.archivedData(withRootObject: location, requiringSecureCoding: false)
            set(encoded, forKey: Self.lastLocationUserDefaultsKey)
        }
    }
    
    private static let preferredUnitLengthUserDefaultsKey = "preferredUnitLengthUserDefaultsKey"
    var preferredUnitLength: UnitLength {
        get {
            guard let data = UserDefaults.standard.data(forKey: Self.preferredUnitLengthUserDefaultsKey),
                  let unarchived = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UnitLength.self, from: data) else {
                return .kilometers
            }
            return unarchived
        } set {
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: false) else {
                removeObject(forKey: Self.preferredUnitLengthUserDefaultsKey)
                return
            }
            UserDefaults.standard.set(data, forKey: Self.preferredUnitLengthUserDefaultsKey)
        }
    }
}
