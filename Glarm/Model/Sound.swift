//
//  Sound.swift
//  Glarm
//
//  Created by Adam Wienconek on 17/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import Foundation
import UserNotifications

struct Sound: Codable {
    internal init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
    
    let name: String
    
    /// URL of the sound, can be local, remote, or just file name. For playback, remember to use `playbackUrl`.
    let url: URL
}

extension Sound {
    var isLocal: Bool {
        return url.absoluteString.prefix(4) != "http"
    }
    
    var playbackUrl: URL {
        // Files in Bundle will be here
        if url.isFileURL {
            return url
        }
        if isLocal {
            return SoundsDirectory.files.url.appendingPathComponent(url.path, isDirectory: false)
        }
        return url
    }
    
    var notificationSoundName: UNNotificationSoundName {
        return UNNotificationSoundName(url.lastPathComponent)
    }
}

extension Sound {
    static var `default`: Sound {
        let name = "Bulletin"
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "Bulletin", ofType: ".caf")!)
        return Sound(name: name, url: url)
    }
}

extension Sound: Equatable {}
