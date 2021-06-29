//
//  WidgetAlarmsManager.swift
//  Glarm
//
//  Created by Adam Wienconek on 29/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import Foundation
import UserNotifications
import CoreDataManager

class WidgetAlarmsManager: CoreDatabaseManager<AlarmEntry> {
    private var notificationCenter: UNUserNotificationCenter { .current() }
    
    override var dataModel: CoreDataModel { .appModel }
    
    func getAlarm(completion: @escaping (AlarmEntry?) -> Void) {
        guard let alarms = fetchAll()?.sorted(by: \.dateCreated, ascending: false) else {
            completion(nil)
            return
        }
        
        notificationCenter.getPendingNotificationRequests { requests in
            let identifiers = requests.map(\.identifier)
            let alarm = alarms.first(where: {
                identifiers.contains($0.uid)
            })
            completion(alarm)
        }
    }
}
