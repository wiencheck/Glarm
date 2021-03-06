//
//  LocalizedStringKeys.swift
//  Plum 2
//
//  Created by Adam Wienconek on 03.06.2018.
//  Copyright © 2018 Adam Wienconek. All rights reserved.
//

import Foundation

extension String {
    func localized(bundle: Bundle = .main, tableName: LanguageTableKey) -> String {
        return NSLocalizedString(self, tableName: tableName.rawValue, value: "**\(self)**", comment: "")
    }
}

protocol LocalizableString {
    var localized: String { get }
}

extension LocalizableString where Self: RawRepresentable, Self.RawValue == String {
    var localized: String {
        return self.rawValue.localized(tableName: .preferred)
    }
}

enum LocalizedStringKey: String, LocalizableString {
    // MARK: Screen titles
    case title_launch
    case title_browser
    case title_edit
    case title_map
    case title_audio
    
    // MARK: Browse screen
    case browse_activeSection
    case browse_markedSection
    case browse_pastSection
    case browse_createButtonTitle
    case browse_backButton
    case browse_showNote
    
    // MARK: Browse edit actions.
    case browse_markAction
    case browse_unmarkAction
    case browse_scheduleAction
    case browse_deleteAction
    case browse_cancelAction
    case browse_changesNotSavedTitle
    case browse_changesNotSavedDetail
    case browse_changesSchedule
    case browse_changesDiscard
    
    // MARK: Edit screen
    case edit_locationHeader
    case edit_noteHeader
    case edit_categoryHeader
    case edit_settingsHeader
    case edit_clearNoteButton
    case edit_notePlaceholder
    case edit_toneCell
    case edit_repeatsCell
    case edit_scheduleButton
    case edit_updateButton
    case edit_backButton
    case edit_exactScrubbingMessage
    
    // MARK: Category screen
    case category_none
    case category_createButton
    case category_defaultHeader
    case category_customHeader
    case category_footer
    case category_newCategoryMessage
    case category_newCategoryPlaceholder
    
    // MARK: Default categories
    case categories_work
    case categories_travel
    case categories_school
    
    // MARK: Audio screen
    case audio_playButtonTitle
    case audio_pauseButtonTitle
    case audio_moreSoundsHeader
    case audio_toneBrowserFooter
    case audio_downloadMoreSounds
    case audio_downloadSoundsFooter
    
    // MARK: Empty cell
    case emptyCell_title
    case emptyCell_detail
    case emptyView_title
    case emptyView_detail
    
    // MARK: Notification
    case notification_title
    case notification_messageIsLessThan
    case notification_messageAway
    case notification_youAre
    case notification_awayFromDestination
    
    // MARK: Map screen
    case map_searchbarPlaceholder
    case map_chooseDestination
    case map_setRadius
    
    // MARK: Info alert
    case about_title
    case about_detail
    case about_leaveReview
    case about_messageMe
    case about_helpLocalization
    
    // MARK: Tips
    case tips_title
    case tips_description
    
    // MARK: Review
    case review_areYouEnjoyingTitle
    case review_areYouEnjoyingMessage
    
    // MARK: Messages
    case message_errorOccurred
    case message_errorUnknown
    
    // MARK: Permissions
    case permission_locationDeniedTitle
    case permission_locationDeniedMessage
    case permission_notificationDeniedTitle
    case permission_notificationDeniedMessage
    case permission_openSettingsAction
    case permission_openAppAction
    
    // MARK: Donate
    case donate_small
    case donate_big
    case donate_medium
    case donate_action
    case donate_title
    case donate_message
    case donate_thankYouTitle
    case donate_thankYouMessage
    
    // MARK: Unlock
    case unlock_thankYouTitle
    case unlock_thankYouMessage
    /// "Unlock all features" alert title
    case unlock_purchaseTitle
    case unlock_purchaseMessage
    /// "Unlock"
    case unlock_purchaseAction
    case unlock_restoreAction
    
    // MARK: Units
    case unit_menuTitle
    case unit_kilometers
    case unit_miles
    
    // MARK: Other
    case cancel
    case dismiss
    case `continue`
    case unlock
    case create
}

extension LocalizedStringKey: CustomStringConvertible {
    var description: String {
        return self.localized
    }
}
