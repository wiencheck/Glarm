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
    
    private func scheduleAlarm(at path: IndexPath) {
        guard let alarm = alarm(at: path) else {
            return
        }
        manager.delegate = self
        manager.schedule(alarm: alarm)
    }
    
    private func cancelAlarm(at path: IndexPath) {
        guard let alarm = alarm(at: path) else {
            return
        }
        manager.cancel(alarm: alarm)
        loadData()
    }
    
    private func markAlarm(at path: IndexPath) {
        guard let alarm = alarm(at: path) else {
            return
        }
        manager.mark(alarm: alarm)
        loadData()
    }
    
    private func unmarkAlarm(at path: IndexPath) {
        guard let alarm = alarm(at: path) else {
            return
        }
        manager.unmark(alarm: alarm)
        loadData()
    }
    
    func createPressed() {
        PermissionsManager.shared.requestLocationPermission { status in
            switch status {
            case .authorized:
                self.delegate?.model(didSelectEditAlarm: self, alarm: nil)
            case .resticted:
                let actions: [UIAlertAction] = [
                    UIAlertAction(localizedTitle: .openSettings, style: .default, handler: { _ in
                        UIApplication.shared.openSettings()
                    }),
                    .cancel(text: LocalizedStringKey.continue.localized) {
                        self.delegate?.model(didSelectEditAlarm: self, alarm: nil)
                    }
                ]
                let model = AlertViewModel(localizedTitle: .locationPermissionDeniedTitle, message: .locationPermissionDeniedMessage, actions: actions, style: .alert)
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
    
    func cellModel(for path: IndexPath) -> AlarmCellViewModel? {
        guard let section = Section(rawValue: path.section),
            let alarm = alarms[section]?[path.row] else {
                return nil
        }
        return AlarmCellViewModel(locationInfo: alarm.locationInfo, date: DateFormatter.localizedString(from: alarm.date, dateStyle: .short, timeStyle: .none), marked: alarm.isMarked)
    }
    
    func headerTitle(in section: Int) -> String? {
        guard let sec = Section(rawValue: section),
            alarms[sec]?.isEmpty == false else {
                return nil
        }
        switch sec {
        case .active:
            return LocalizedStringKey.activeSection.localized
        case .marked:
            return LocalizedStringKey.markedSection.localized
        case .past:
            return LocalizedStringKey.pastSection.localized
        }
    }
    
    func didSelectRow(at path: IndexPath) {
        guard let section = Section(rawValue: path.section),
            let alarm = alarms[section]?.at(path.row) else {
                return
        }
        delegate?.model(didSelectEditAlarm: self, alarm: alarm)
    }
    
    func editingActions(at path: IndexPath) -> [UITableViewRowAction]? {
        let section = Section(rawValue: path.section)!

        guard let alarm = alarms[section]?.at(path.row) else {
            return nil
        }
        
        var actions: [UITableViewRowAction] = []
        
        if alarm.isActive {
            let cancel = UITableViewRowAction(style: .default, title: LocalizedStringKey.cancel.localized, handler: { _, path in
                self.cancelAlarm(at: path)
            })
            cancel.backgroundColor = .systemRed
            actions.append(cancel)
        } else {
            let schedule = UITableViewRowAction(style: .default, title: LocalizedStringKey.scheduleActionTitle.localized, handler: { _, path in
                self.scheduleAlarm(at: path)
            })
            schedule.backgroundColor = .purple
            actions.append(schedule)
        }
        if alarm.isMarked {
            let unmark = UITableViewRowAction(style: .default, title: LocalizedStringKey.unmarkActionTitle.localized, handler: { _, path in
                self.unmarkAlarm(at: path)
            })
            unmark.backgroundColor = .tint
            actions.append(unmark)
        } else {
            let mark = UITableViewRowAction(style: .default, title: LocalizedStringKey.markActionTitle.localized, handler: { _, path in
                self.markAlarm(at: path)
            })
            mark.backgroundColor = .tint
            actions.append(mark)
        }
        
        return actions
    }
}
