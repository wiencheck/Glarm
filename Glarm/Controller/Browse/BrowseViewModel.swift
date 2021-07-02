//
//  BrowseViewModel.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 06/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import AWAlertController
import ReviewKit

protocol BrowseViewModelDelegate: Alertable {
    func model(didUpdate model: BrowseViewModel, scrollToTop: Bool)
    func model(didSelectEditAlarm model: BrowseViewModel, alarm: AlarmEntryProtocol?)
    func model(didEncounterError model: BrowseViewModel, error: Error)
}

final class BrowseViewModel {
    var manager: AlarmsManagerProtocol
    
    private var dataObserver: Any?
    private var applicationObserver: Any?
    weak var delegate: BrowseViewModelDelegate?
    
    init(manager: AlarmsManagerProtocol) {
        self.manager = manager
        setObservers(true)
    }
    
    deinit {
        setObservers(false)
    }
    
    private var alarms = [String: [AlarmEntryProtocol]]()
        
    private var sectionNames = [String]()
    
    func loadData() {
        manager.fetchAlarms { alarms in
            self.sort(alarms: alarms)
            self.delegate?.model(didUpdate: self, scrollToTop: true)
        }
    }
    
    private func sort(alarms: [AlarmEntryProtocol]) {
        var newAlarms: [String: [AlarmEntryProtocol]] = [:]
        var categoryNames = [String]()
        
        for alarm in alarms.sorted(by: \.dateCreated, .orderedDescending) {
            let key: String
            if alarm.isActive {
                key = activeSection.title
            } else if alarm.isMarked {
                key = markedSection.title
            } else if let name = alarm.category?.name {
                key = name
                categoryNames.append(name)
            } else {
                key = pastSection.title
            }
            newAlarms.appendValue(alarm, toArrayAtKey: key)
        }
        
        self.sectionNames = {
            var sections: [String] = [
                activeSection.title,
                markedSection.title,
                pastSection.title
            ]
            sections.insert(contentsOf: categoryNames.sorted(), at: sections.lastIndex)
            return sections
        }()
        self.alarms = newAlarms
    }
    
    func alarm(at path: IndexPath) -> AlarmEntryProtocol? {
        let section = sectionNames[path.section]
        return alarms[section]?[path.row]
    }
    
    func scheduleAlarm(at path: IndexPath) -> Bool {
        guard let alarm = alarm(at: path) else {
            return false
        }
        manager.delegate = self
        if let error = manager.schedule(alarm: alarm) {
            delegate?.displayErrorMessage(title: nil, error: error)
            return false
        }
        return true
    }
    
    func cancelAlarm(at path: IndexPath) -> Bool {
        guard let alarm = alarm(at: path) else {
            return false
        }
        if let error = manager.cancel(alarm: alarm) {
            delegate?.displayErrorMessage(title: nil, error: error)
            return false
        }
        loadData()
        return true
    }
    
    func markAlarm(atPath path: IndexPath, marked: Bool) {
        guard var alarm = alarm(at: path) else {
            return
        }
        alarm.isMarked = marked
        manager.saveChanges(forAlarm: alarm)
    }
    
    private func setObservers(_ active: Bool) {
        if let observer = applicationObserver {
            NotificationCenter.default.removeObserver(observer, name: UIApplication.didBecomeActiveNotification, object: nil)
        }
        if let observer = dataObserver {
            NotificationCenter.default.removeObserver(observer, name: AlarmsManager.alarmsUpdatedNotification, object: nil)
        }
        
        guard active else { return }
        applicationObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
            self?.loadData()
        }
        dataObserver = NotificationCenter.default.addObserver(forName: AlarmsManager.alarmsUpdatedNotification, object: nil, queue: nil) { [weak self] _ in
            self?.loadData()
        }
    }
    
    func deleteAlarm(at path: IndexPath) -> Bool {
        guard let alarm = alarm(at: path) else {
                return false
        }
        if let error = manager.delete(alarm: alarm) {
            delegate?.displayErrorMessage(title: nil, error: error)
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
    func alarmsManager(notificationScheduled manager: AlarmsManagerProtocol, error: Error?) {
        if let error = error {
            delegate?.model(didEncounterError: self, error: error)
        } else {
            loadData()
        }
        AppReviewManager.attemptPresentingAlert()
    }
    
    func alarmsManager(notificationWasPresented manager: AlarmsManagerProtocol) {
        loadData()
    }
}

extension BrowseViewModel: AlarmEditControllerDelegate {
    
    func editController(_ controller: AlarmEditController, didDisappearWithoutSavingChanges modifiedAlarm: AlarmEntryProtocol) {
        if modifiedAlarm.locationInfo == .default {
            manager.discardChanges(forAlarm: modifiedAlarm)
            return
        }
        
        let actions: [UIAlertAction] = [
            UIAlertAction(localizedTitle: .browse_changesSchedule, style: .default, handler: { [weak self] _ in
                self?.manager.delegate = self
                if let error = self?.manager.schedule(alarm: modifiedAlarm) {
                    self?.delegate?.displayErrorMessage(title: nil, error: error)
                }
            }),
            .cancel(localizedText: .browse_changesDiscard, action: { [weak self] in
                self?.manager.discardChanges(forAlarm: modifiedAlarm)
            })
        ]
        
        let model = AlertViewModel(localizedTitle: .browse_changesNotSavedTitle, message: .browse_changesNotSavedDetail, actions: actions, style: .alert)
        delegate?.didReceiveAlert(model: model)
    }
}

extension BrowseViewModel {
    var numberOfSections: Int {
        // Adding active and past sections
        return sectionNames.count
    }
    
    func numberOfRows(in section: Int) -> Int {
        let section = sectionNames[section]
        return alarms[section]?.count ?? 0
    }
    
    func cellModel(for path: IndexPath) -> AlarmCell.Model? {
        guard let alarm = self.alarm(at: path) else {
            return nil
        }
        var model = AlarmCell.Model(alarm: alarm)
        // Prevent displaying category name in category sections
        if !staticSections.map(\.index).contains(path.section) {
            model.category?.name = ""
        }
        return model
    }
    
    func headerTitle(in section: Int) -> String {
        let name = sectionNames[section]
        let sec = Section(section, name)
        return localizedSectionTitle(forSection: sec)
    }
}

private extension BrowseViewModel {
    typealias Section = (index: Int, title: String)
    
    var activeSection: Section {
        return (0, "###active###")
    }
    
    var markedSection: Section {
        return (1, "###marked###")
    }
    
    var pastSection: Section {
        return (sectionNames.lastIndex, "###past###")
    }
    
    var staticSections: [Section] {
        [activeSection, markedSection, pastSection]
    }
    
    func localizedSectionTitle(forSection section: Section) -> String {
        switch section.index {
        case activeSection.index:
            return .localized(.browse_activeSection)
        case markedSection.index:
            return .localized(.browse_markedSection)
        case pastSection.index:
            return .localized(.browse_pastSection)
        default:
            return section.title
        }
    }
}

extension Dictionary where Value == [AlarmEntryProtocol] {
    mutating func appendValue(_ newValue: AlarmEntryProtocol, toArrayAtKey key: Key) {
        if self[key] == nil {
            self[key] = [newValue]
        } else {
            self[key]!.append(newValue)
        }
    }
}

extension Dictionary {
    mutating func merge(_ rhs: [Key: Value], overwriting: Bool = true) {
        rhs.forEach { key, value in
            if self[key] == nil || overwriting {
                self[key] = value
            }
        }
    }
}

extension Collection {
    var lastIndex: Int {
        return Swift.max(0, count - 1)
    }
}
