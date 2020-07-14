//
//  AlarmTone.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 08/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UserNotifications

enum AlarmTone: String, Codable, CaseIterable {
    case bulletin = "Bulletin"
    case constellation = "Constellation"
    case cosmic = "Cosmic"
    case ripples = "Ripples"
    case slowRise = "Slow Rise"
    case summit = "Summit"
}

extension AlarmTone {
    static var `default`: AlarmTone {
        get {
            guard let name = UserDefaults.standard.string(forKey: "defaultToneName"), let tone = AlarmTone(rawValue: name) else {
                return .bulletin
            }
            return tone
        } set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "defaultToneName")
        }
    }
    
    var soundName: UNNotificationSoundName {
        return UNNotificationSoundName(rawValue + ".caf")
    }
}
