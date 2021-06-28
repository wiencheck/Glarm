//
//  AlarmsManager.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 06/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import CoreLocation
import UserNotifications
import AVFoundation
import NotificationCenter
import UIKit
import CoreDataManager
import AWAlertController
import CoreData

final class NewAlarmsManager: CoreDatabaseManager<AlarmEntry>, AlarmsManagerProtocol {
    
    // MARK: - Public Properties
    
    weak var delegate: AlarmsManagerDelegate?
    
    private let notificationCenter: UNUserNotificationCenter
    private var isScheduling = false
        
    override init() {
        notificationCenter = .current()
        super.init()
        notificationCenter.delegate = self
    }
    
    override var dataModel: CoreDataModel {
        CoreDataModel(name: "Glarm", usesCloud: true)
    }
    
    func schedule(alarm: AlarmEntryProtocol) -> Error? {
        guard let entry = alarm as? DatabaseRecord else {
            fatalError()
        }
        askForNotificationPermissions(for: entry)
        return nil
    }
    
    func cancel(alarm: AlarmEntryProtocol) -> Error? {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [alarm.uid])
        print("Scheduled alarm with uuid: \(alarm.uid)")
        return nil
    }
    
    func delete(alarm: AlarmEntryProtocol) -> Error? {
        guard let entry = alarm as? DatabaseRecord else {
            fatalError()
        }
        return deleteOne(record: entry)
    }
    
    func makeNewAlarm() -> AlarmEntryProtocol {
        return AlarmEntry(context: context)
    }
    
    func saveChanges(forAlarm alarm: AlarmEntryProtocol) {
        saveChanges()
    }
    
    func discardChanges(forAlarm alarm: AlarmEntryProtocol) {
        guard let record = alarm as? DatabaseRecord else {
            fatalError()
        }
        if record.isSaved {
            record.discardChanges()
        } else {
            deleteOne(record: record)
        }
        // The default notification does not fire in either case
        // In first because changes were not yet saved
        // In second one because the record hasn't been yet inserted into context
        NotificationCenter.default.post(name: Self.alarmsUpdatedNotification, object: self)
    }
    
    func updateNewestAlarm(representation: AlarmEntryRepresentation) {
        UserDefaults.appGroupSuite.currentAlarmRepresentation = representation
        UserDefaults.appGroupSuite.synchronize()
    }
    
    func fetchAlarms(completion: @escaping ([AlarmEntryProtocol]) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            let identifiers = Set(requests.map { $0.identifier })
            let alarms = self.fetchAll() ?? []
            
            for alarm in alarms {
                alarm.isActive = identifiers.contains(alarm.uid)
            }
            
            completion(alarms)
        }
    }
    
    override func postNotification(_ sender: Notification) {
        super.postNotification(sender)
        if isScheduling { return }
        NotificationCenter.default.post(name: Self.alarmsUpdatedNotification, object: self)
    }
}

private extension NewAlarmsManager {
    func askForNotificationPermissions(for alarm: DatabaseRecord) {
        PermissionsManager.shared.requestNotificationsPermission { status in
            guard status == .authorized else {
                self.delegate?.alarmsManager(notificationPermissionDenied: self)
                return
            }
            self.scheduleNotification(for: alarm)
        }
    }
    
    func scheduleNotification(for alarm: DatabaseRecord) {
        defer {
            isScheduling = false
        }
        isScheduling = true
        
        // Delete old alarm from database, if exists.
        
        if alarm.managedObjectContext == nil {
            if let error = insert(alarm) {
                delegate?.alarmsManager(notificationScheduled: self, error: error)
                return
            }
            print("Inserted new alarm with uuid: \(alarm.uuid)")
        }
        scheduleNotification(forAlarm: alarm) { [weak self] error in
            guard let self = self else { return }
            
            var err = error
            outerif: if err == nil {
                if let uuid = alarm.value(forKey: "uuid") as? UUID,
                   self.contains(recordKey: uuid) {
                    break outerif
                } else {
                    alarm.isSaved = true
                    err = self.insert(alarm)
                }
            }
            self.delegate?.alarmsManager(notificationScheduled: self, error: err)
        }
    }
    
}

extension NewAlarmsManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert])
        // delegate?.alarmsManager(notificationWasPresented: self)
    }
}

extension NewAlarmsManager {
    static let alarmsUpdatedNotification = Notification.Name("alarmsUpdatedNotification")
}
