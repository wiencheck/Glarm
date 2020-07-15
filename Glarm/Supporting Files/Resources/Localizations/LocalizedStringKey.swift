//
//  LocalizedStringKeys.swift
//  Plum 2
//
//  Created by Adam Wienconek on 03.06.2018.
//  Copyright © 2018 Adam Wienconek. All rights reserved.
//

import Foundation

extension String {
    func localized(bundle: Bundle = .main, tableName: LanguageTableKey = .english) -> String {
        return NSLocalizedString(self, tableName: tableName.rawValue, value: "**\(self)**", comment: "")
    }
}

protocol LocalizableString {
    var localized: String { get }
}

extension LocalizableString where Self: RawRepresentable, Self.RawValue == String {
    var localized: String {
        let table = LanguageTableKey(locale: Locale.current) ?? .english
        return self.rawValue.localized(tableName: table)
    }
}

enum LocalizedStringKey: String, LocalizableString {
    case launchTitle
    case browserTitle
    case editTitle
    case mapTitle
    case audioTitle
    
    case activeSection
    case markedSection
    case pastSection
    
    case createButtonTitle
    case playButtonTitle
    case pauseButtonTitle
    case toneBrowserFooter
    case searchLocationPlaceholder
    case choosePlacemark
    case setDistance
    case location
    case tone
    
    case markActionTitle
    case unmarkActionTitle
    case scheduleActionTitle
    case schedule
    case update
    case cancel
    case alarm
    case alarms
    
    case emptyCellTitle
    case emptyCellDetail
    case emptyViewTitle
    case emptyViewDetail
    
    case notificationTitle
    case notificationMessageIsLessThan
    case notificationMessageAway
    case youAre
    case awayFromDestination
    
    case infoTitle
    case infoDetail
    case leaveReview
    case messageMe
    case dismiss
    case `continue`
    case openTips
    case tipsDescription
    case areYouEnjoyingTitle
    case areYouEnjoyingMessage
    case errorOccurred
    case errorUnknown
    
    case permissionLocation
    case permissionNotifications
    case locationPermissionDeniedTitle
    case locationPermissionDeniedMessage
    case notificationPermissionDeniedTitle
    case notificationPermissionDeniedMessage
    case openSettings
    case openApp
    case disclaimerFirst
    case disclaimerSecond
    case locationDisclaimer
    case notificationDisclaimer
}

extension LocalizedStringKey: CustomStringConvertible {
    var description: String {
        return self.localized
    }
}
