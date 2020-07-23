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
    
    private(set)var alarms = [Section: [AlarmEntry]]()
    
    func loadData() {
        var countBefore = 0
        for value in alarms.values {
            countBefore += value.count
        }
        manager.fetchAlarms { alarms in
            self.alarms = alarms
            var countAfter = 0
            for value in alarms.values {
                countAfter += value.count
            }
            self.delegate?.model(didUpdate: self, scrollToTop: countBefore != countAfter)
        }
    }
    
    private func alarm(at path: IndexPath) -> AlarmEntry? {
        guard let section = Section(rawValue: path.section) else {
            return nil
        }
        return alarms[section]?.at(path.row)
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
    
    private func markAlarm(at path: IndexPath) -> Bool {
        guard UnlockManager.unlocked else {
            AWAlertController.presentUnlockController(in: delegate)
            return false
        }
        guard let alarm = alarm(at: path) else {
            return false
        }
        manager.mark(alarm: alarm)
        loadData()
        return true
    }
    
    private func unmarkAlarm(at path: IndexPath) -> Bool {
        guard let alarm = alarm(at: path) else {
            return false
        }
        manager.unmark(alarm: alarm)
        loadData()
        return true
    }
    
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

extension BrowseViewModel {
    typealias Section = AlarmState
    
    var numberOfSections: Int {
        return Section.count
    }
    
    func numberOfRows(in section: Int) -> Int {
        let sec = Section(rawValue: section)!
        let count = alarms[sec]?.count ?? 0
        return count
    }
    
    func cellModel(for path: IndexPath) -> AlarmCell.Model? {
        guard let section = Section(rawValue: path.section),
            let alarm = alarms[section]?[path.row] else {
                return nil
        }
        return AlarmCell.Model(alarm: alarm)
    }
    
    func headerTitle(in section: Int) -> String? {
        guard let sec = Section(rawValue: section),
            alarms[sec]?.isEmpty == false else {
                return nil
        }
        switch sec {
        case .active:
            return LocalizedStringKey.browse_activeSection.localized
        case .marked:
            return LocalizedStringKey.browse_markedSection.localized
        case .past:
            return LocalizedStringKey.browse_pastSection.localized
        }
    }
    
    func didSelectRow(at path: IndexPath) {
        guard let section = Section(rawValue: path.section),
            let alarm = alarms[section]?.at(path.row) else {
                return
        }
        delegate?.model(didSelectEditAlarm: self, alarm: alarm)
    }
    
    func editingActions(at path: IndexPath) -> [UIContextualAction]? {
        let section = Section(rawValue: path.section)!

        guard let alarm = alarms[section]?.at(path.row) else {
            return nil
        }
        
        var actions: [UIContextualAction] = []
        
        if alarm.isActive {
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
        
        if alarm.isMarked {
            let unmark = UIContextualAction(style: .normal, title: LocalizedStringKey.browse_unmarkAction.localized, handler: { _, _, completion in
                let success = self.unmarkAlarm(at: path)
                BrowseViewController.swipeActionsUseCounter += 1
                completion(success)
            })
            unmark.backgroundColor = .tint
            actions.append(unmark)
        } else {
            let mark = UIContextualAction(style: .normal, title: LocalizedStringKey.browse_markAction.localized, handler: { _, _, completion in
                let success = self.markAlarm(at: path)
                BrowseViewController.swipeActionsUseCounter += 1
                completion(success)
            })
            mark.backgroundColor = .tint
            actions.append(mark)
        }
        
        return actions
    }
}
