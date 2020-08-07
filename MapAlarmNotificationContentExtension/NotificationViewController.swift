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

    @IBOutlet var label: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }
    
    func didReceive(_ notification: UNNotification) {
        self.label?.text = notification.request.content.body
    }

}
