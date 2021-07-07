//
//  AlarmsManagerProtocol.swift
//  Glarm
//
//  Created by Adam Wienconek on 23/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import UIKit
import UserNotifications
import CoreLocation
import WidgetKit

protocol AlarmsManagerProtocol {
    var delegate: AlarmsManagerDelegate? { get set }
    
    /// Schedules alarm and saves it to the database.
    @discardableResult
    func schedule(alarm: AlarmEntryProtocol) -> Error?
    
    /// Cancels scheduled alarm.
    @discardableResult
    func cancel(alarm: AlarmEntryProtocol) -> Error?
    
    /// Deleted alarm from the database.
    @discardableResult
    func delete(alarm: AlarmEntryProtocol) -> Error?
    
    /// Loads current state of saved alarms from the database.
    func fetchAlarms(completion: @escaping ([AlarmEntryProtocol]) -> Void)
    
    /// Creates and returns new alarm object with clean state.
    func makeNewAlarm() -> AlarmEntryProtocol
    
    /// Saves changes for the alarm to the database.
    func saveChanges(forAlarm alarm: AlarmEntryProtocol)
    
    /// Discards any changes made to the alarm after last save operation.
    func discardChanges(forAlarm alarm: AlarmEntryProtocol)
}

extension AlarmsManagerProtocol {
    private var notificationCenter: UNUserNotificationCenter { .current() }
    
    func updateRecentAlarms(withAlarms alarms: [AlarmEntry]?) {
        let recentAlarms = alarms?.map { entry in
            entry.makeSimplified()
        }
        UserDefaults.appGroupSuite.recentAlarms = recentAlarms
        UserDefaults.appGroupSuite.synchronize()
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Schedules new notification to fire fot given alarm.
    func scheduleNotification(forAlarm alarm: AlarmEntryProtocol, completion: ((Error?) -> Void)?) {
        guard let locationInfo = alarm.locationInfo else {
            completion?("Location info cannot be empty")
            return
        }
        
        let notification = notificationContent(for: alarm)
        let destRegion = destinationRegion(locationInfo: locationInfo)
        let trigger = UNLocationNotificationTrigger(region: destRegion, repeats: false)
        
        let request = UNNotificationRequest(identifier: alarm.uid,
                                            content: notification,
                                            trigger: trigger)
        
        self.notificationCenter.getPendingNotificationRequests { requests in
            // Delete pending alarm from notification center, if exists.
            if let request = requests.first(where: { $0.identifier == alarm.uid }) {
                self.notificationCenter.removePendingNotificationRequests(withIdentifiers: [request.identifier])
            }
            
            self.notificationCenter.add(request) { error in
                
                if error == nil {
                    print("Scheduled alarm with uuid: \(alarm.uid)")
                }
                completion?(error)
            }
        }
    }
    
    /// Returns content for configuring notification for the alarm.
    private func notificationContent(for alarm: AlarmEntryProtocol) -> UNMutableNotificationContent {
        let notification = UNMutableNotificationContent()
        if UnlockManager.unlocked {
            notification.categoryIdentifier = SharedConstants.notificationContentExtensionCategory
        }
        
        notification.title = LocalizedStringKey.notification_title.localized
        notification.body = "\(alarm.locationInfo?.name ?? "–") \(LocalizedStringKey.notification_messageIsLessThan.localized) \(alarm.locationInfo?.radius.readableRepresentation() ?? "–") \(LocalizedStringKey.notification_messageAway.localized)."
        
        if UnlockManager.unlocked, let thumbnailUrl = UIImage.createLocalUrl(forAssetNamed: UIImage.notificationThumbnailAssetName),
            let thumbnailAttachment = try? UNNotificationAttachment(identifier: "thumbnail", url: thumbnailUrl, options: nil) {
            notification.attachments = [thumbnailAttachment]
        }
        
        if let url = SoundsManager.url(forSoundNamed: alarm.soundName) {
            let soundName = UNNotificationSoundName(url.lastPathComponent)
            notification.sound = UNNotificationSound(named: soundName)
        }
        return notification
    }
    
    /// Configures region where alarm will be fired.
    private func destinationRegion(locationInfo: LocationNotificationInfo) -> CLCircularRegion {
        let destRegion = CLCircularRegion(center: locationInfo.coordinate,
                                          radius: locationInfo.radius,
                                          identifier: locationInfo.name)
        destRegion.notifyOnEntry = true
        destRegion.notifyOnExit = false
        return destRegion
    }
    
    /// Displays random alarm notification from available alarms.
    func displayRandomAlarm(delay: TimeInterval = 1) {
        fetchAlarms { alarms in
            guard let alarm = alarms.randomElement() else {
                return
            }
            let notificationCenter = UNUserNotificationCenter.current()
            PermissionsManager.shared.requestNotificationsPermission { status in
                guard status == .authorized else {
                    self.delegate?.alarmsManager(notificationPermissionDenied: self)
                    return
                }
                
                let notification = self.notificationContent(for: alarm)
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
                
                let request = UNNotificationRequest(identifier: "randomAlarm",
                                                    content: notification,
                                                    trigger: trigger)
                
                notificationCenter.getPendingNotificationRequests { requests in
                    notificationCenter.add(request) { error in
                        guard let error = error else { return }
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
}
