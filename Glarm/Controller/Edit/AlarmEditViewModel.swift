//
//  AlarmEditViewModel.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 06/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import CoreLocation
import UIKit

protocol AlarmEditViewModelDelegate: Alertable {
    func model(didSelectMap model: AlarmEditViewModel, locationInfo: LocationNotificationInfo)
    func model(didSelectAudio model: AlarmEditViewModel, sound: Sound)
    func model(didReloadRow model: AlarmEditViewModel, at indexPath: IndexPath)
    func model(didReloadSection model: AlarmEditViewModel, section: Int)
    func model(didScheduleAlert model: AlarmEditViewModel, error: Error?)
    func model(didChangeButton model: AlarmEditViewModel)
}

final class AlarmEditViewModel {
    
    let manager: AlarmsManager
    
    let scheduleButtonTitle: String
    
    private var alarm: AlarmEntry
    
    private var edited = false {
        didSet {
            delegate?.model(didChangeButton: self)
        }
    }
    
    weak var delegate: AlarmEditViewModelDelegate?
    
    init(manager: AlarmsManager, alarm: AlarmEntry?) {
        self.manager = manager
        self.alarm = alarm ?? AlarmEntry()
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
        return edited
    }
    
    func schedulePressed() {
        manager.delegate = self
        manager.schedule(alarm: alarm)
    }
    
    func updateAlarmNote(text: String) {
        if text == alarm.note {
            return
        }
        edited = true
        alarm.note = text
    }
}

extension AlarmEditViewModel: AlarmsManagerDelegate {
    func alarmsManager(notificationScheduled manager: AlarmsManager, error: Error?) {
        delegate?.model(didScheduleAlert: self, error: error)
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
        edited = true
        alarm.locationInfo = info
        delegate?.model(didReloadRow: self, at: IndexPath(row: 0, section: Section.location.rawValue))
    }
}

extension AlarmEditViewModel: AudioBrowserViewControllerDelegate {
    func audio(didReturnTone controller: AudioBrowserViewController, sound: Sound) {
        if alarm.sound == sound {
            return
        }
        updateAudio(sound: sound)
    }
    
    func updateAudio(sound: Sound) {
        edited = true
        alarm.sound = sound
        delegate?.model(didReloadRow: self, at: IndexPath(row: 0, section: Section.audio.rawValue))
    }
}

extension AlarmEditViewModel {
    enum Section: Int, CaseIterable {
        case location
        case note
        case audio
    }
    
    var numberOfSections: Int {
        return Section.count
    }
    
    func numberOfRows(in section: Int) -> Int {
        return 1
    }
    
    func didSelectRow(at path: IndexPath) {
        switch Section(rawValue: path.section)! {
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
        case .note:
            break
        case .audio:
            delegate?.model(didSelectAudio: self, sound: alarm.sound)
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
        case .audio:
            return nil
        }
    }
}

extension AlarmEditViewModel {
    var alarmLocationInfo: LocationNotificationInfo {
        return alarm.locationInfo
    }
    
    var alarmToneName: String {
        return alarm.sound.name
    }
    
    var alarmNoteText: String {
        return alarm.note
    }
}
