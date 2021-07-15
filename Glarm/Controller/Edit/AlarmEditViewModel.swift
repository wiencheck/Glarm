//
//  AlarmEditViewModel.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 06/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import CoreLocation
import UIKit
import ReviewKit

protocol AlarmEditViewModelDelegate: Alertable {
    func model(didSelectMap model: AlarmEditViewModel, locationInfo: LocationNotificationInfo?)
    func model(didSelectCategory model: AlarmEditViewModel, category: Category?)
    func model(didSelectAudio model: AlarmEditViewModel, soundName: String)
    func model(didReloadRow model: AlarmEditViewModel, at indexPath: IndexPath)
    func model(didReloadSection model: AlarmEditViewModel, section: Int)
    func model(didScheduleAlert model: AlarmEditViewModel, error: Error?)
    func model(didChangeButton model: AlarmEditViewModel)
}

final class AlarmEditViewModel {
    
    var manager: AlarmsManagerProtocol
    var categoriesManager: AlarmCategoriesManagerProtocol
    
    let scheduleButtonTitle: String
    
    private(set) var alarm: AlarmEntryProtocol {
        didSet {
            print("alarm change")
        }
    }
    
    private(set)var didMakeChanges = false {
        didSet {
            delegate?.model(didChangeButton: self)
        }
    }
    
    private(set)var didSaveChanges = false
    
    weak var delegate: AlarmEditViewModelDelegate?
    
    init(manager: AlarmsManagerProtocol, alarm: AlarmEntryProtocol?) {
        self.manager = manager
        self.categoriesManager = AppDelegate.shared.categoriesManager
        self.alarm = alarm ?? manager.makeNewAlarm()
        if let alarm = alarm {
            scheduleButtonTitle = alarm.isActive ? LocalizedStringKey.edit_updateButton.localized : LocalizedStringKey.edit_scheduleButton.localized
        } else {
            scheduleButtonTitle = LocalizedStringKey.edit_scheduleButton.localized
        }
    }
    
    var noteClearButtonText: String? {
        guard UnlockManager.unlocked else {
            return LocalizedStringKey.unlock.localized
        }
        return alarmNoteText.isEmpty ? nil : LocalizedStringKey.edit_clearNoteButton.localized
    }
    
    var scheduleButtonEnabled: Bool {
        guard alarm.isActive else {
            return alarm.locationInfo != .default
        }
        return didMakeChanges
    }
    
    func schedulePressed() {
        manager.delegate = self
        if let error = manager.schedule(alarm: alarm) {
            delegate?.displayErrorMessage(title: .localized(.message_errorOccurred), error: error)
            return
        }
        didSaveChanges = true
    }
    
    func updateAlarmNote(text: String) {
        if text == alarm.note {
            return
        }
        alarm.note = text.trimmingCharacters(in: .whitespacesAndNewlines)
        didMakeChanges = true
    }
    
    func setAlarmMarked(_ marked: Bool) {
        alarm.isMarked = marked
        manager.saveChanges(forAlarm: alarm)
    }
    
    func setAlarmRepeating(_ repeating: Bool) {
        alarm.isRecurring = repeating
        didMakeChanges = true
    }
}

extension AlarmEditViewModel: AlarmsManagerDelegate {
    func alarmsManager(notificationScheduled manager: AlarmsManagerProtocol, error: Error?) {
        delegate?.model(didScheduleAlert: self, error: error)
        AppReviewManager.attemptPresentingAlert()
    }
}

extension AlarmEditViewModel: AlarmMapControllerDelegate {
    func map(didReturnLocationInfo controller: MapController, locationInfo: LocationNotificationInfo) {
        if alarm.locationInfo == locationInfo {
            return
        }
        updateLocationInfo(info: locationInfo)
    }
    
    func updateLocationInfo(info: LocationNotificationInfo) {
        didMakeChanges = true
        alarm.locationInfo = info
        delegate?.model(didReloadRow: self, at: IndexPath(row: 0, section: Section.location.rawValue))
    }
}

extension AlarmEditViewModel: AudioBrowserViewControllerDelegate {
    func audio(didReturnTone controller: AudioBrowserViewController, soundName: String) {
        if alarm.soundName == soundName {
            return
        }
        updateAudio(withSoundName: soundName)
    }
    
    private func updateAudio(withSoundName soundName: String) {
        didMakeChanges = true
        alarm.soundName = soundName
        delegate?.model(didReloadRow: self, at: IndexPath(row: 1, section: Section.settings.rawValue))
    }
}

extension AlarmEditViewModel: CategoriesViewControllerDelegate {
    func categories(didReturnCategory controller: CategoriesViewController, category: Category?) {
        if alarm.category == category {
            return
        }
        updateCategory(category)
    }
    
    private func updateCategory(_ category: Category?) {
        if !didMakeChanges {
            didMakeChanges = alarm.category != category
        }
        categoriesManager.assign(alarm: alarm, toCategory: category)
    }
}

extension AlarmEditViewModel {
    enum Section: Int, CaseIterable {
        case location
        case note
        case category
        case settings
        
        var numberOfRows: Int {
            switch self {
            case .settings:
                return 2
            default:
                return 1
            }
        }
        
        var repeatsRow: Int {
            guard self == .settings else { return NSNotFound }
            return 0
        }
        
        var soundRow: Int {
            guard self == .settings else { return NSNotFound }
            return 1
        }
    }
    
    var numberOfSections: Int {
        return Section.count
    }
    
    func numberOfRows(in section: Int) -> Int {
        let sec = Section(rawValue: section)!
        return sec.numberOfRows
    }
    
    func didSelectRow(at path: IndexPath) {
        let section = Section(rawValue: path.section)!
        switch section {
        case .location:
            PermissionsManager.shared.requestLocationPermission { status in
                switch status {
                case .authorized:
                    self.delegate?.model(didSelectMap: self, locationInfo: self.alarm.locationInfo)
                case .resticted:
                    let actions: [UIAlertAction] = [
                        UIAlertAction(localizedTitle: .permission_openSettingsAction, style: .default, handler: { _ in
                            UIApplication.shared.openSettings()
                        }),
                        .cancel(text: LocalizedStringKey.continue.localized) {
                            self.delegate?.model(didSelectMap: self, locationInfo: self.alarm.locationInfo)
                        }
                    ]
                    let model = AlertViewModel(localizedTitle: .permission_locationDeniedTitle, message: .permission_locationDeniedMessage, actions: actions, style: .alert)
                    self.delegate?.didReceiveAlert(model: model)
                case .notDetermined:
                    break
                }
            }
        case .category:
            delegate?.model(didSelectCategory: self, category: alarm.category)
        case .settings:
            if path.row == section.soundRow {
                delegate?.model(didSelectAudio: self, soundName: alarm.soundName)
            }
        default:
            break
        }
    }
    
    func cellModel(for path: IndexPath) -> AlarmCell.Model? {
        if alarm.locationInfo == .default {
            return nil
        }
        return AlarmCell.Model(locationInfo: alarm.locationInfo, note: nil)
    }
    
    func headerModel(in section: Int) -> TableHeaderView.Model? {
        guard let sec = Section(rawValue: section) else {
                return nil
        }
        switch sec {
        case .location:
            return .init(title: LocalizedStringKey.edit_locationHeader.localized)
        case .note:
            return .init(title: LocalizedStringKey.edit_noteHeader.localized,
                buttonTitle: noteClearButtonText)
        case .category:
            return .init(title: LocalizedStringKey.edit_categoryHeader.localized)
        case .settings:
            return .init(title: LocalizedStringKey.edit_settingsHeader.localized)
        }
    }
}

extension AlarmEditViewModel {
    var alarmLocationInfo: LocationNotificationInfo? {
        return alarm.locationInfo
    }
    
    var alarmToneName: String {
        return alarm.soundName
    }
    
    var alarmNoteText: String {
        return alarm.note
    }
    
    var alarmCategory: Category? {
        return alarm.category
    }
}
