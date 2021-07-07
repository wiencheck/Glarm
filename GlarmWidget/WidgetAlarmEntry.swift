//
//  WidgetAlarmEntry.swift
//  GlarmWidgetExtension
//
//  Created by Adam Wienconek on 29/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import WidgetKit
import SwiftUI
import MapKit

struct WidgetAlarmEntry: TimelineEntry {
    let date: Date
    let snapshot: UIImage
    let distance: CLLocationDistance
    let timeOfArrival: Date?
    
    private let alarm: SimpleAlarmEntryProtocol
    
    init(date: Date = Date(), snapshot: UIImage, alarm: SimpleAlarmEntryProtocol, distance: CLLocationDistance, timeOfArrival: Date?) {
        self.date = date
        self.snapshot = snapshot
        self.alarm = alarm
        self.distance = distance
        self.timeOfArrival = timeOfArrival
    }
    
    var name: String { alarm.locationInfo?.name ?? "None" }
    
    var note: String { alarm.note }
    
    var url: URL? { URL(string: "//:\(alarm.uid)") }
}

extension SimpleAlarmEntry {
    static var placeholder: SimpleAlarmEntry {
        /* Cupertino, of course. */
        let locationInfo = LocationNotificationInfo(name: "Cupertino",
                                                    coordinate: .cupertino,
                                                    radius: 20000)
        let alarm = SimpleAlarmEntry(locationInfo: locationInfo, note: "Say hello to Mr Cook!")
        
        return alarm
    }
}

extension WidgetAlarmEntry {
    static var placeholder: WidgetAlarmEntry {
        let snapshot = UIImage(named: "Notification_Thumbnail")!
        /* Cupertino, of course. */
        let locationInfo = LocationNotificationInfo(name: "Cupertino",
                                                    coordinate: .cupertino,
                                                    radius: 5500)
        let alarm = SimpleAlarmEntry(locationInfo: locationInfo, note: "Say hello to Mr Cook!")
        let timeOfArrival = Calendar.current.date(byAdding: .minute, value: 40, to: Date())
        return WidgetAlarmEntry(snapshot: snapshot,
                                alarm: alarm,
                                distance: 10000,
                                timeOfArrival: timeOfArrival)
    }
    /*
     placeholder
     empty
     error
     */
}
