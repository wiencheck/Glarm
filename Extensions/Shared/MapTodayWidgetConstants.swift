//
//  ExtensionConstants.swift
//  MapTodayWidgetExtension
//
//  Created by Adam Wienconek on 05/08/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import Foundation

enum ExtensionConstants {
    /// Key for accesing app's `UserDefaults` suite.
    static let userDefaultsSuiteName = "group.adw.glarm"
    
    /// Key under `SimplifiedAlarmEntry` object data is placed.
    static let activeAlarmDefaultsKey = "ActiveAlarmDefaultsKey"
    
    static let widgetTargetBundleIdentifier = "com.adw.glarm.TodayWidgetExtension"
    
    static let notificationContentExtensionCategory = "NotificationContentExtension"
}
