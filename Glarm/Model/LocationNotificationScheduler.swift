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
import UIKit

enum AlarmState: Int, CaseIterable {
    case active
    case marked
    case past
}

protocol AlarmsManagerDelegate: class {
    func alarmsManager(locationPermissionDenied manager: AlarmsManager)
    func alarmsManager(notificationPermissionDenied manager: AlarmsManager)
    func alarmsManager(notificationScheduled manager: AlarmsManager, error: Error?)
    func alarmsManager(notificationWasPresented manager: AlarmsManager)
}

extension AlarmsManagerDelegate {
    func alarmsManager(locationPermissionDenied manager: AlarmsManager) {
        guard let vc = UIApplication.shared.keyWindow()?.rootViewController else {
            return
        }
        let model = AlertViewModel(localizedTitle: .locationPermissionDeniedTitle, message: .locationPermissionDeniedMessage, actions: [.cancel()], style: .alert)
        vc.present(AWAlertController(model: model), animated: true, completion: nil)
    }
    
    func alarmsManager(notificationPermissionDenied manager: AlarmsManager) {
        guard let vc = UIApplication.shared.keyWindow()?.rootViewController else {
            return
        }
        let model = AlertViewModel(localizedTitle: .notificationPermissionDeniedTitle, message: .notificationPermissionDeniedMessage, actions: [.cancel()], style: .alert)
        vc.present(AWAlertController(model: model), animated: true, completion: nil)
    }
    
    func alarmsManager(notificationScheduled manager: AlarmsManager, error: Error?) {
        guard let error = error, let vc = UIApplication.shared.keyWindow()?.rootViewController else {
            return
        }
        vc.displayErrorMessage(title: "Couldn't schedule alarm", error: error)
    }
    
    func alarmsManager(notificationWasPresented manager: AlarmsManager) {
        
    }
}

final class AlarmsManager: NSObject {
    
    // MARK: - Public Properties
    
    weak var delegate: AlarmsManagerDelegate?
    
    // MARK: - Private Properties
    
    private lazy var notificationCenter: UNUserNotificationCenter = {
        let n = UNUserNotificationCenter.current()
        n.delegate = self
        return n
    }()
            
    func schedule(alarm: AlarmEntry) {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            PermissionsManager.shared.requestLocationPermission { authorized in
                guard authorized else {
                    self.delegate?.alarmsManager(locationPermissionDenied: self)
                    return
                }
                self.askForNotificationPermissions(for: alarm)
            }
        case .authorizedWhenInUse, .authorizedAlways:
            askForNotificationPermissions(for: alarm)
        default:
            delegate?.alarmsManager(locationPermissionDenied: self)
            break
        }
    }
    
    func cancel(alarm: AlarmEntry) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [alarm.identifier])
    }
    
    func mark(alarm: AlarmEntry) {
        alarm.isMarked = true
        alarms.update(with: alarm)
    }
    
    func unmark(alarm: AlarmEntry) {
        alarm.isMarked = false
        alarms.update(with: alarm)
    }
}

// MARK: - Private Functions

private extension AlarmsManager {
    func askForNotificationPermissions(for alarm: AlarmEntry) {
        guard CLLocationManager.locationServicesEnabled() else {
            return
        }
        PermissionsManager.shared.requestNotificationsPermission { authorized in
            guard authorized else {
                self.delegate?.alarmsManager(notificationPermissionDenied: self)
                return
            }
            self.scheduleNotification(for: alarm)
        }
    }
    
    func scheduleNotification(for alarm: AlarmEntry) {
        alarm.date = Date()
        alarms.update(with: alarm)
        
        let notification = notificationContent(for: alarm)
        let destRegion = destinationRegion(locationInfo: alarm.locationInfo)
        let trigger = UNLocationNotificationTrigger(region: destRegion, repeats: false)
        
        let request = UNNotificationRequest(identifier: alarm.identifier,
                                            content: notification,
                                            trigger: trigger)
        
        notificationCenter.getPendingNotificationRequests { requests in
            // Remove duplicates
            if requests.contains(where: { $0.identifier == alarm.identifier }) {
                self.alarms.remove(alarm)
                self.notificationCenter.removePendingNotificationRequests(withIdentifiers: [alarm.identifier])
            }
            
            self.notificationCenter.add(request) { [weak self] (error) in
                self?.alarms.insert(alarm)
                guard let self = self else {
                    return
                }
                if error == nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        AppRatingHelper.askForReview()
                    }
                }
                DispatchQueue.main.async {
                    self.delegate?.alarmsManager(notificationScheduled: self, error: error)
                }
            }
        }
    }
    
    func notificationContent(for alarm: AlarmEntry) -> UNMutableNotificationContent {
        let notification = UNMutableNotificationContent()
        notification.title = LocalizedStringKey.notificationTitle.localized
        notification.body = "\(alarm.locationInfo.identifier) \(LocalizedStringKey.notificationMessageIsLessThan.localized) \(alarm.locationInfo.radius.readableRepresentation) \(LocalizedStringKey.notificationMessageAway.localized)."
        notification.sound = UNNotificationSound(named: alarm.tone.soundName)
        return notification
    }
    
    func destinationRegion(locationInfo: LocationNotificationInfo) -> CLCircularRegion {
        let destRegion = CLCircularRegion(center: locationInfo.coordinate,
                                          radius: locationInfo.radius,
                                          identifier: locationInfo.identifier)
        destRegion.notifyOnEntry = true
        destRegion.notifyOnExit = false
        return destRegion
    }
}

extension AlarmsManager {
    func fetchAlarms(completion: @escaping ([AlarmState: [AlarmEntry]]) -> Void) {
        
        var active = Set<AlarmEntry>()
        var marked = Set<AlarmEntry>()
        var past = Set<AlarmEntry>()
                
        // Get active and past alarms
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiers = requests.map { $0.identifier }
            let alarms = self.alarms
                        
            for alarm in alarms {
                if identifiers.contains(alarm.identifier) {
                    alarm.isActive = true
                    active.insert(alarm)
                } else if alarm.isMarked {
                    marked.insert(alarm)
                } else {
                    past.insert(alarm)
                }
            }
            completion([
                .active: active.sorted(by: {$0.date>$1.date}),
                .marked: marked.sorted(by: {$0.date>$1.date}),
                .past:  past.sorted(by: {$0.date>$1.date})
            ])
        }
    }
    
    fileprivate(set) var alarms: Set<AlarmEntry> {
        get {
            guard let data = UserDefaults.standard.data(forKey: "alarms"),
                let arr = try? JSONDecoder().decode(Set<AlarmEntry>.self, from: data) else {
                return []
            }
            return arr
        } set {
            let marked = newValue.filter { $0.isMarked }
            // 11 15 9
            let unmarked = newValue.subtracting(marked).sorted(by: {
                $0.date > $1.date
                }).prefix(10)
            guard let data = try? JSONEncoder().encode(marked.union(unmarked)) else {
                return
            }
            UserDefaults.standard.set(data, forKey: "alarms")
        }
    }
}

extension AlarmsManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert])
        delegate?.alarmsManager(notificationWasPresented: self)
    }
}
