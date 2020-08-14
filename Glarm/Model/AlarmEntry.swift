//
//  AlarmEntry.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 06/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import Foundation

final class AlarmEntry: SimplifiedAlarmEntry {
    var category: String
    var sound: Sound
    var date: Date
    
    var isActive = false
    
    init(info: LocationNotificationInfo, category: String, sound: Sound, note: String) {
        self.category = category
        self.sound = sound
        date = Date()
        super.init(info: info, note: note)
    }
    
    convenience init() {
        self.init(info: LocationNotificationInfo(), category: "", sound: SoundsManager.selectedSound, note: "")
    }
    
    // MARK: Codable stuff.
    private enum CodingKeys: String, CodingKey {
        case category
        case sound
        case date
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        category = try container.decode(String.self, forKey: .category)
        sound = try container.decode(Sound.self, forKey: .sound)
        date = try container.decode(Date.self, forKey: .date)
        try super.init(from: container.superDecoder())
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(category, forKey: .category)
        try container.encode(sound, forKey: .sound)
        try container.encode(date, forKey: .date)
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
