//
//  NotificationViewController.swift
//  MapAlarmNotificationContentExtension
//
//  Created by Adam Wienconek on 30/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {
    
    private lazy var mapController = ExtensionViewController(shouldDisplayMap: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        add(child: mapController)
    }
    
    func didReceive(_ notification: UNNotification) {
        guard let data = notification.request.content.userInfo["alarm"] as? Data,
            let alarm = try? JSONDecoder().decode(AlarmEntryRepresentation.self, from: data) else {
                return
        }
        mapController.configure(with: alarm)
    }
}
