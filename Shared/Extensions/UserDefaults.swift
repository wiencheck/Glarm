//
//  UserDefaults.swift
//  Glarm
//
//  Created by Adam Wienconek on 24/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import Foundation

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
}
