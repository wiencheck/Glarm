//
//  AlarmsManagerDelegate.swift
//  Glarm
//
//  Created by Adam Wienconek on 23/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import Foundation
import UIKit
import AWAlertController

protocol AlarmsManagerDelegate: AnyObject {
    func alarmsManager(locationPermissionDenied manager: AlarmsManagerProtocol)
    func alarmsManager(notificationPermissionDenied manager: AlarmsManagerProtocol)
    func alarmsManager(notificationScheduled manager: AlarmsManagerProtocol, error: Error?)
    func alarmsManager(notificationWasPresented manager: AlarmsManagerProtocol)
}

extension AlarmsManagerDelegate {
    func alarmsManager(locationPermissionDenied manager: AlarmsManagerProtocol) {
        guard let vc = UIApplication.shared.keyWindow()?.rootViewController else {
            return
        }
        let actions: [UIAlertAction] = [
            UIAlertAction(localizedTitle: .permission_openSettingsAction, style: .default, handler: { _ in
                UIApplication.shared.openSettings()
            }),
            .cancel(text: LocalizedStringKey.dismiss.localized)
        ]
        let model = AlertViewModel(localizedTitle: .permission_locationDeniedTitle, message: .permission_locationDeniedMessage, actions: actions, style: .alert)
        vc.present(AWAlertController(model: model), animated: true, completion: nil)
    }
    
    func alarmsManager(notificationPermissionDenied manager: AlarmsManagerProtocol) {
        guard let vc = UIApplication.shared.keyWindow()?.rootViewController else {
            return
        }
        vc.present(AWAlertController.notificationsPermissionRestrictedAlert, animated: true, completion: nil)
    }
    
    func alarmsManager(notificationScheduled manager: AlarmsManagerProtocol, error: Error?) {
        guard let error = error, let vc = UIApplication.shared.keyWindow()?.rootViewController else {
            return
        }
        vc.displayErrorMessage(title: "Couldn't schedule alarm", error: error)
    }
    
    func alarmsManager(notificationWasPresented manager: AlarmsManagerProtocol) {
        
    }
}
