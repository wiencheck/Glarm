//
//  PermissionsManager.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 08/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import CoreLocation
import UserNotifications

final class PermissionsManager: NSObject {
    static let shared = PermissionsManager()
    
    private override init() {
        super.init()
    }
    
    func getLocationPermissionStatus(completion: @escaping (AuthorizationStatus) -> Void) {
        completion(AuthorizationStatus(status: CLLocationManager.authorizationStatus()))
    }
    
    func requestLocationPermission(completion: @escaping (AuthorizationStatus) -> Void) {
        LocationManager.shared.requestAuthorization { status in
            completion(status)
        }
    }
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    func getNotificationsPermissionStatus(completion: @escaping (AuthorizationStatus) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(AuthorizationStatus(settings: settings))
            }
        }
    }
    
    func requestNotificationsPermission(completion: @escaping (AuthorizationStatus) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { authorized, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("*** Couldn't grant notification permission, error: \(error.localizedDescription)")
                    completion(.notDetermined)
                    return
                }
                guard authorized else {
                    completion(.resticted)
                    return
                }
                let category = UNNotificationCategory(identifier: ExtensionConstants.notificationContentExtensionCategory, actions: [], intentIdentifiers: [], options: [])
                self.notificationCenter.setNotificationCategories(Set([category]))
                completion(.authorized)
            }
        }
    }
}
