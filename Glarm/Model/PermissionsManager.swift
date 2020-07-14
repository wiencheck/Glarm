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
    
    private let locationManager = CLLocationManager()
    private var onLocationPermissionChange: ((Bool) -> Void)!
    
    func getLocationPermissionStatus(completion: @escaping (Bool) -> Void) {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            completion(true)
        default:
            completion(false)
        }
    }

    func requestLocationPermission(completion: @escaping (Bool) -> Void) {
        getLocationPermissionStatus { authorized in
            if authorized {
                completion(true)
                return
            }
            self.onLocationPermissionChange = completion
            self.locationManager.delegate = self
            self.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    func getNotificationsPermissionStatus(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                completion(true)
            default:
                completion(false)
            }
        }
    }
    
    func requestNotificationsPermission(completion: @escaping (Bool) -> Void) {
        getNotificationsPermissionStatus { authorized in
            if authorized {
                completion(true)
                return
            }
            self.notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { authorized, error in
                if let error = error {
                    print("*** Couldn't grant notification permission, error: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                completion(authorized)
            }
        }
    }
}

extension PermissionsManager: CLLocationManagerDelegate {
    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            onLocationPermissionChange(true)
        default:
            onLocationPermissionChange(false)
        }
    }
}
