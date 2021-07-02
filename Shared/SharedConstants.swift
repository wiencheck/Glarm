//
//  SharedConstants.swift
//  Glarm
//
//  Created by Adam Wienconek on 29/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import Foundation
import UIKit

enum SharedConstants {
    static let radiusOverlayAlpha: CGFloat = 0.4
    
    static let appGroupIdentifier = "group.adw.glarm"
    
    static var appGroupContainerURL: URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)!
    }
    
    static let recentAlarmsUserDefaultsKey = "recentAlarms"
    
    static let widgetTargetBundleIdentifier = "com.adw.glarm.TodayWidgetExtension"
    
    static let notificationContentExtensionCategory = "NotificationContentExtension"
}
