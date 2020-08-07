//
//  UserDefaults.swift
//  Glarm
//
//  Created by Adam Wienconek on 05/08/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import Foundation

extension UserDefaults {
    static var appGroupSuite: UserDefaults {
        return UserDefaults(suiteName: ExtensionConstants.userDefaultsSuiteName)!
    }
    
    func alarm(forKey key: String) -> SimplifiedAlarmEntry? {
        guard let data = data(forKey: key),
            let alarm = try? JSONDecoder().decode(SimplifiedAlarmEntry.self, from: data) else {
                return nil
        }
        return alarm
    }
    
    @discardableResult
    func set(_ alarm: SimplifiedAlarmEntry, forKey key: String) -> Bool {
        guard let data = try? JSONEncoder().encode(alarm) else {
            return false
        }
        set(data, forKey: key)
        return true
    }
}
