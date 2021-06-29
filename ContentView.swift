//
//  ContentView.swift
//  Glarm
//
//  Created by Adam Wienconek on 29/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import SwiftUI
import MapKit
import UserNotifications

struct ContentView: View {
    @State private var alarm: AlarmEntry?
    
    private let manager = WidgetAlarmsManager()
    
    var body: some View {
        Text(alarm?.locationInfo?.name ?? "No location")
            .performOnLoad {
                loadRecentAlarm()
            }
    }
    
    private func loadRecentAlarm() {
        manager.getAlarm { alarm in
            self.alarm = alarm
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension View {
    @ViewBuilder
    func performOnLoad(action: @escaping () -> Void) -> some View {
        if #available(iOS 15.0, *) {
            // task(action)
        } else {
            onAppear(perform: action)
        }
    }
}
