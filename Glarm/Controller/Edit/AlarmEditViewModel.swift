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
    func model(didSelectAudio model: AlarmEditViewModel, tone: AlarmTone)
    func model(didReloadRow model: AlarmEditViewModel, at indexPath: IndexPath)
    func model(didScheduleAlert model: AlarmEditViewModel, error: Error?)
}

final class AlarmEditViewModel {
    
    let manager: AlarmsManager
    
    let scheduleButtonTitle: String
    
    private var alarm: AlarmEntry
    
    private var edited = false
    
    weak var delegate: AlarmEditViewModelDelegate?
    
    init(manager: AlarmsManager, alarm: AlarmEntry?) {
        self.manager = manager
        self.alarm = alarm ?? AlarmEntry()
        if let alarm = alarm {
            scheduleButtonTitle = alarm.isActive ? LocalizedStringKey.update.localized : LocalizedStringKey.schedule.localized
        } else {
            scheduleButtonTitle = LocalizedStringKey.schedule.localized
        }
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
    func audio(didReturnTone controller: AudioBrowserViewController, tone: AlarmTone) {
        if alarm.tone == tone {
            return
        }
        updateAudio(tone: tone)
    }
    
    func updateAudio(tone: AlarmTone) {
        edited = true
        alarm.tone = tone
        delegate?.model(didReloadRow: self, at: IndexPath(row: 0, section: Section.audio.rawValue))
    }
}

extension AlarmEditViewModel {
    enum Section: Int, CaseIterable {
        case location
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
                        UIAlertAction(localizedTitle: .openSettings, style: .default, handler: { _ in
                            UIApplication.shared.openSettings()
                        }),
                        .cancel(text: LocalizedStringKey.continue.localized) {
                            self.delegate?.model(didSelectMap: self, locationInfo: self.alarm.locationInfo)
                        }
                    ]
                    let model = AlertViewModel(localizedTitle: .locationPermissionDeniedTitle, message: .locationPermissionDeniedMessage, actions: actions, style: .alert)
                    self.delegate?.didReceiveAlert(model: model)
                case .notDetermined:
                    break
                }
            }
        case .audio:
            delegate?.model(didSelectAudio: self, tone: alarm.tone)
        }
    }
    
    func cellModel(for path: IndexPath) -> AlarmCellViewModel? {
        if alarm.locationInfo == .default {
            return nil
        }
        return AlarmCellViewModel(locationInfo: alarm.locationInfo)
    }
    
    var alarmToneName: String {
        return alarm.tone.rawValue
    }
    
    func headerTitle(in section: Int) -> String? {
        guard let sec = Section(rawValue: section) else {
                return nil
        }
        switch sec {
        case .location:
            return LocalizedStringKey.location.localized
        case .audio:
            return nil
        }
    }
}
