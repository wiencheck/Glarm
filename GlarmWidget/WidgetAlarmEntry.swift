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
    let alarm: SimpleAlarmEntryProtocol
    
    init(date: Date = Date(), snapshot: UIImage, alarm: SimpleAlarmEntryProtocol) {
        self.date = date
        self.snapshot = snapshot
        self.alarm = alarm
    }
    
    var url: URL? { URL(string: "//:\(alarm.uid)") }
}

extension WidgetAlarmEntry {
    static var placeholder: WidgetAlarmEntry {
        /* Cupertino, of course. */
        let coordinate = CLLocationCoordinate2D(latitude: 4131143.90984374, longitude: 585748.287490468)
        let locationInfo = LocationNotificationInfo(name: "Cupertino",
                                                    coordinate: coordinate,
                                                    radius: 20000)
        let alarm = SimpleAlarmEntry(locationInfo: locationInfo, note: "Placeholder")
        return WidgetAlarmEntry(snapshot: .add, alarm: alarm)
    }
    /*
     placeholder
     empty
     error
     */
}
