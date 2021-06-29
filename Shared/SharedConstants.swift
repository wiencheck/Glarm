//
//  SharedConstants.swift
//  Glarm
//
//  Created by Adam Wienconek on 29/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import Foundation

enum SharedConstants {
    static let appGroupIdentifier = "group.adw.glarm"
    
    static var appGroupContainerURL: URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)!
    }
    
    /// Key under `SimplifiedAlarmEntry` object data is placed.
    static let activeAlarmDefaultsKey = "ActiveAlarmDefaultsKey"
    
    static let widgetTargetBundleIdentifier = "com.adw.glarm.TodayWidgetExtension"
    
    static let notificationContentExtensionCategory = "NotificationContentExtension"
}
