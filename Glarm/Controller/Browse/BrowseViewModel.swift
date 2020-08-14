//
//  BrowseViewModel.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 06/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit

protocol BrowseViewModelDelegate: Alertable {
    func model(didUpdate model: BrowseViewModel, scrollToTop: Bool)
    func model(didSelectEditAlarm model: BrowseViewModel, alarm: AlarmEntry?)
    func model(didEncounterError model: BrowseViewModel, error: Error)
}

final class BrowseViewModel {
    let manager: AlarmsManager
    
    private var observer: Any?
    weak var delegate: BrowseViewModelDelegate? {
        didSet {
            if delegate == nil, let observer = observer {
                NotificationCenter.default.removeObserver(observer, name: UIApplication.didBecomeActiveNotification, object: nil)
            } else {
                observer = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { _ in
                    self.loadData()
                }
            }
        }
    }
    
    init(manager: AlarmsManager) {
        self.manager = manager
    }
    
    //private var alarms = [AlarmState: [AlarmEntry]]()
    private var activeAlarms = [AlarmEntry]()
    private var markedAlarms = [String: [AlarmEntry]]()
    private var pastAlarms = [AlarmEntry]()
    
    private var categoryNames = [String]()
    
    private var sectionNames: [String] = [
        LocalizedStringKey.browse_activeSection.localized,
        LocalizedStringKey.browse_pastSection.localized
    ]
    
    let activeSection: Int = 0
    var pastSection: Int {
        return markedAlarms.count + 1
    }
    
    func loadData() {
        manager.fetchAlarms { alarms in
            self.configure(with: alarms)
            self.delegate?.model(didUpdate: self, scrollToTop: true)
        }
    }
    
    private func configure(with alarms: [AlarmState: [AlarmEntry]]) {
        activeAlarms = alarms[.active] ?? []
        markedAlarms.removeAll()
        if let marked = alarms[.marked] {
            for alarm in marked {
                if markedAlarms[alarm.category] == nil {
                    markedAlarms.updateValue([alarm], forKey: alarm.category)
                } else {
                    markedAlarms[alarm.category]!.append(alarm)
                }
            }
            categoryNames = markedAlarms.keys.sorted()
        }
        pastAlarms = alarms[.past] ?? []
    }
    
//    private func sectionName(for section: Int) -> String? {
//        if section == activeSection {
//            return .localized(.browse_activeSection)
//        } else if section == pastSection {
//            return .localized(.browse_pastSection)
//        } else if let category = categoryNames.at(section) {
//            return category
//        }
//        return nil
//    }
    
    private func alarm(at path: IndexPath) -> AlarmEntry? {
        if path.section == activeSection {
            return activeAlarms.at(path.row)
        } else if let category = categoryNames.at(path.section - 1) {
            return markedAlarms[category]?.at(path.row)
        } else if path.section == pastSection {
            return pastAlarms.at(path.row)
        }
        return nil
    }
    
    private func scheduleAlarm(at path: IndexPath) -> Bool {
        guard let alarm = alarm(at: path) else {
            return false
        }
        manager.delegate = self
        manager.schedule(alarm: alarm)
        return true
    }
    
    private func cancelAlarm(at path: IndexPath) -> Bool {
        guard let alarm = alarm(at: path) else {
            return false
        }
        manager.cancel(alarm: alarm)
        loadData()
        return true
    }
    
    //    private func markAlarm(at path: IndexPath) -> Bool {
    //        guard UnlockManager.unlocked else {
    //            AWAlertController.presentUnlockController(in: delegate)
    //            return false
    //        }
    //        guard let alarm = alarm(at: path) else {
    //            return false
    //        }
    //        manager.mark(alarm: alarm)
    //        loadData()
    //        return true
    //    }
    //
    //    private func unmarkAlarm(at path: IndexPath) -> Bool {
    //        guard let alarm = alarm(at: path) else {
    //            return false
    //        }
    //        manager.unmark(alarm: alarm)
    //        loadData()
    //        return true
    //    }
    
    private func deleteAlarm(at path: IndexPath) -> Bool {
        guard let alarm = alarm(at: path),
            manager.delete(alarm: alarm) else {
                return false
        }
        loadData()
        return true
    }
    
    func createPressed() {
        PermissionsManager.shared.requestLocationPermission { status in
            switch status {
            case .authorized:
                self.delegate?.model(didSelectEditAlarm: self, alarm: nil)
            case .resticted:
                let actions: [UIAlertAction] = [
                    UIAlertAction(localizedTitle: .permission_openSettingsAction, style: .default, handler: { _ in
                        UIApplication.shared.openSettings()
                    }),
                    .cancel(text: LocalizedStringKey.continue.localized) {
                        self.delegate?.model(didSelectEditAlarm: self, alarm: nil)
                    }
                ]
                let model = AlertViewModel(localizedTitle: .permission_locationDeniedTitle, message: .permission_locationDeniedMessage, actions: actions, style: .alert)
                self.delegate?.didReceiveAlert(model: model)
            case .notDetermined:
                break
            }
        }
    }
}

extension BrowseViewModel: AlarmsManagerDelegate {  
    func alarmsManager(notificationScheduled manager: AlarmsManager, error: Error?) {
        if let error = error {
            delegate?.model(didEncounterError: self, error: error)
        } else {
            loadData()
        }
    }
    
    func alarmsManager(notificationWasPresented manager: AlarmsManager) {
        loadData()
    }
}

extension BrowseViewModel: AlarmEditControllerDelegate {
    func editController(_ controller: AlarmEditController, didDisappearWithoutSavingChanges modifiedAlarm: AlarmEntry) {
        let actions: [UIAlertAction] = [
            UIAlertAction(localizedTitle: .browse_changesSchedule, style: .default, handler: { [weak self] _ in
                self?.manager.delegate = self
                self?.manager.schedule(alarm: modifiedAlarm)
            }),
            .cancel(localizedText: .browse_changesDiscard)
        ]
        
        let model = AlertViewModel(localizedTitle: .browse_changesNotSavedTitle, message: .browse_changesNotSavedDetail, actions: actions, style: .alert)
        delegate?.didReceiveAlert(model: model)
    }
}

extension BrowseViewModel {
    var numberOfSections: Int {
        // Adding active and past sections
        return categoryNames.count + 2
    }
    
    func numberOfRows(in section: Int) -> Int {
        if section == activeSection {
            return activeAlarms.count
        } else if let category = categoryNames.at(section - 1) {
            return markedAlarms[category]?.count ?? 0
        } else if section == pastSection {
            return pastAlarms.count
        }
        return 0
    }
    
    func cellModel(for path: IndexPath) -> AlarmCell.Model? {
        guard let alarm = self.alarm(at: path) else {
            return nil
        }
        var model = AlarmCell.Model(alarm: alarm)
        // Prevent displaying category name in category sections
        if !(path.section == activeSection || path.section == pastSection) {
            model.category = nil
        }
        return model
    }
    
    func headerTitle(in section: Int) -> String? {
        if section == activeSection {
            return .localized(.browse_activeSection)
        } else if section == pastSection {
            return .localized(.browse_pastSection)
        } else if let category = categoryNames.at(section - 1) {
            return category
        }
        return nil
    }
    
    func didSelectRow(at path: IndexPath) {
        guard let a = alarm(at: path) else {
            return
        }
        delegate?.model(didSelectEditAlarm: self, alarm: a)
    }
    
    func editingActions(at path: IndexPath) -> [UIContextualAction]? {
        guard let a = alarm(at: path) else {
            return nil
        }
        var actions: [UIContextualAction] = []
        
        if a.isActive {
            let cancel = UIContextualAction(style: .normal, title: LocalizedStringKey.cancel.localized, handler: { _, _, completion in
                let success = self.cancelAlarm(at: path)
                BrowseViewController.swipeActionsUseCounter += 1
                completion(success)
            })
            cancel.backgroundColor = .systemRed
            actions.append(cancel)
        } else {
            let delete = UIContextualAction(style: .destructive, title: LocalizedStringKey.browse_deleteAction.localized) { _, _, completion in
                let success = self.deleteAlarm(at: path)
                BrowseViewController.swipeActionsUseCounter += 1
                completion(success)
            }
            actions.append(delete)
            
            let schedule = UIContextualAction(style: .normal, title: LocalizedStringKey.browse_scheduleAction.localized, handler: { _, _, completion in
                let success = self.scheduleAlarm(at: path)
                BrowseViewController.swipeActionsUseCounter += 1
                completion(success)
            })
            schedule.backgroundColor = .purple
            actions.append(schedule)
        }
        
        return actions
    }
}
