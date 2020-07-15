//
//  AuthorizationStatus.swift
//  Glarm
//
//  Created by Adam Wienconek on 15/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import CoreLocation.CLLocationManager
import UserNotifications.UNNotificationSettings
import UIKit.UIDevice

enum AuthorizationStatus {
    case notDetermined
    case authorized
    case resticted
    
    init(settings: UNNotificationSettings) {
        if UIDevice.current.isSimulator {
            self = .authorized
        } else {
            switch settings.authorizationStatus {
            case .authorized:
                self = .authorized
            case .denied:
                self = .resticted
            default:
                self = .notDetermined
            }
        }
    }
    
    init(status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            self = .authorized
        case .denied, .restricted:
            self = .resticted
        default:
            self = .notDetermined
        }
    }
}
