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
    private class var appGroupSuite: UserDefaults {
        return UserDefaults(suiteName: SharedConstants.appGroupIdentifier)!
    }
    
    private static let recentAlarmsUserDefaultsKey = "recentAlarmsUserDefaultsKey"
    class var recentAlarms: [SimpleAlarmEntry]? {
        get {
            guard let arr = Self.appGroupSuite.array(forKey: Self.recentAlarmsUserDefaultsKey) as? [Data] else {
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
                Self.appGroupSuite.removeObject(forKey: Self.recentAlarmsUserDefaultsKey)
            } else {
                Self.appGroupSuite.set(arr, forKey: Self.recentAlarmsUserDefaultsKey)
            }
            Self.appGroupSuite.synchronize()
        }
    }
    
    private static let lastLocationUserDefaultsKey = "lastSpeedUserDefaultsKey"
    class var lastLocation: CLLocation? {
        get {
            guard let data = Self.appGroupSuite.data(forKey: Self.lastLocationUserDefaultsKey) else {
                return nil
            }
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CLLocation.self, from: data)
        } set {
            guard let location = newValue else {
                Self.appGroupSuite.removeObject(forKey: Self.lastLocationUserDefaultsKey)
                return
            }
            let encoded = try? NSKeyedArchiver.archivedData(withRootObject: location, requiringSecureCoding: false)
            Self.appGroupSuite.set(encoded, forKey: Self.lastLocationUserDefaultsKey)
            Self.appGroupSuite.synchronize()
        }
    }
    
    private static let preferredUnitLengthUserDefaultsKey = "preferredUnitLengthUserDefaultsKey"
    class var preferredUnitLength: UnitLength {
        get {
            guard let data = Self.appGroupSuite.data(forKey: Self.preferredUnitLengthUserDefaultsKey),
                  let unarchived = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UnitLength.self, from: data) else {
                return .kilometers
            }
            return unarchived
        } set {
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: false) else {
                Self.appGroupSuite.removeObject(forKey: Self.preferredUnitLengthUserDefaultsKey)
                return
            }
            Self.appGroupSuite.set(data, forKey: Self.preferredUnitLengthUserDefaultsKey)
            Self.appGroupSuite.synchronize()
        }
    }
}
