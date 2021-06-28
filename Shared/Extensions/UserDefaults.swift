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
        return UserDefaults(suiteName: ExtensionConstants.userDefaultsSuiteName)!
    }
    
    var currentAlarmRepresentation: AlarmEntryRepresentation? {
        get {
            guard let data = data(forKey: Self.currentAlarmRepresentationUserDefaultsKey) else {
                return nil
            }
            return try? JSONDecoder().decode(AlarmEntryRepresentation.self, from: data)
        } set {
            guard let data = try? JSONEncoder().encode(newValue) else {
                return
            }
            set(data, forKey: Self.currentAlarmRepresentationUserDefaultsKey)
        }
    }
    
    private static let currentAlarmRepresentationUserDefaultsKey = "currentAlarmRepresentation"
}
