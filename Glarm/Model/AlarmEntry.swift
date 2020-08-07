//
//  AlarmEntry.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 06/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import Foundation

final class AlarmEntry: SimplifiedAlarmEntry {
    var sound: Sound
    var date: Date
    
    var isMarked = false
    var isActive = false
    
    init(info: LocationNotificationInfo, sound: Sound, note: String) {
        self.sound = sound
        date = Date()
        super.init(info: info, note: note)
    }
    
    convenience init() {
        self.init(info: LocationNotificationInfo(), sound: SoundsManager.selectedSound, note: "")
    }
    
    // MARK: Codable stuff.
    private enum CodingKeys: String, CodingKey {
        case sound
        case date
        case isMarked
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sound = try container.decode(Sound.self, forKey: .sound)
        date = try container.decode(Date.self, forKey: .date)
        isMarked = try container.decode(Bool.self, forKey: .isMarked)
        try super.init(from: container.superDecoder())
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sound, forKey: .sound)
        try container.encode(date, forKey: .date)
        try container.encode(isMarked, forKey: .isMarked)
        try super.encode(to: container.superEncoder())
    }
}

extension AlarmEntry: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

extension AlarmEntry: Equatable {
    static func == (lhs: AlarmEntry, rhs: AlarmEntry) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

extension AlarmEntry {
    /// Returns new, simplified version of itself. Keep in mind that it's a separate object.
    var simplified: SimplifiedAlarmEntry {
        return SimplifiedAlarmEntry(identifier: identifier, info: locationInfo, note: note)
    }
}
