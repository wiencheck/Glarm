//
//  WidgetAlarmsProvider.swift
//  Glarm
//
//  Created by Adam Wienconek on 29/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import SwiftUI
import WidgetKit
import CoreLocation

class WidgetAlarmsProvider: NSObject, TimelineProvider {
    typealias Entry = WidgetAlarmEntry
    
    let locationManager: CLLocationManager
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
    }
    
    deinit {
        locationManager.stopUpdatingLocation()
    }
    
    private var location: CLLocation? { locationManager.location ?? UserDefaults.appGroupSuite.lastLocation }
        
    func getSnapshot(in context: Context, completion: @escaping (WidgetAlarmEntry) -> Void) {
        print("Snapshot")
        
        prepareWidgetEntry(inContext: context, withAlarmEntry: .placeholder) { widgetEntry in
            completion(widgetEntry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetAlarmEntry>) -> Void) {
        print("Timeline")
        
        fetchMostRecentAlarm { alarmEntry in
            guard let alarmEntry = alarmEntry else {
                let timeline = Timeline<WidgetAlarmEntry>(entries: [.placeholder], policy: .never)
                completion(timeline)
                return
            }
            
            self.prepareWidgetEntry(inContext: context, withAlarmEntry: alarmEntry) { widgetEntry in
                let policy: TimelineReloadPolicy
                if let refreshDate = Calendar.current.date(byAdding: .second,
                                                        value: 30,
                                                        to: Date()) {
                    policy = .after(refreshDate)
                } else {
                    policy = .never
                }
                let timeline = Timeline(entries: [widgetEntry],
                                        policy: policy)
                completion(timeline)
            }
        }
    }
    
    func placeholder(in context: Context) -> WidgetAlarmEntry {
        return .placeholder
    }
    
    private func prepareWidgetEntry(inContext context: Context, withAlarmEntry alarmEntry: SimpleAlarmEntry, completion: @escaping (WidgetAlarmEntry) -> Void) {
        let userLocation: CLLocation? = context.isPreview ? .cupertinoUser : location
        
        guard let locationInfo = alarmEntry.locationInfo,
              let distance = userLocation?.distance(from: locationInfo.location) else {
            completion(.placeholder)
            return
        }
        var timeOfArrival: Date?
        
        if let speed = userLocation?.speed,
           speed > 0 {
            let seconds = distance / speed
            timeOfArrival = Calendar.current.date(byAdding: .second, value: Int(seconds), to: Date())
        }
        
        createImage(locationInfo: locationInfo,
                    userLocation: userLocation,
                    size: calculateImageSize(inContext: context)) { snapshot in
            guard let snapshot = snapshot else {
                completion(.placeholder)
                return
            }
            let widgetEntry = WidgetAlarmEntry(snapshot: snapshot,
                                               alarm: alarmEntry,
                                               distance: distance,
                                               timeOfArrival: timeOfArrival)
            completion(widgetEntry)
        }
    }
    
    private func fetchMostRecentAlarm(completion: @escaping (SimpleAlarmEntry?) -> Void) {
        locationManager.startUpdatingLocation()
        
        guard let recentAlarms = UserDefaults.appGroupSuite.recentAlarms?.sorted(by:     \.dateCreated, .orderedDescending) else {
            completion(nil)
            return
        }
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiers = requests.map(\.identifier)
            
            guard let recentAlarm = recentAlarms.first(where: { identifiers.contains($0.uid) }) else {
                completion(nil)
                return
            }
            completion(recentAlarm)
        }
    }
    
    private func calculateImageSize(inContext context: Context) -> CGSize {
        let originalSize = context.displaySize
        
        switch context.family {
        case .systemLarge:
            return CGSize(width: originalSize.width * Constants.largeWidgetImageSizeRatio.width,
                          height: originalSize.height * Constants.largeWidgetImageSizeRatio.height)
        case .systemMedium:
            return CGSize(width: originalSize.width * Constants.mediumWidgetImageSizeRatio.width,
                          height: originalSize.height * Constants.mediumWidgetImageSizeRatio.height)
        default:
            return CGSize(width: originalSize.width * Constants.smallWidgetImageSizeRatio.width,
                          height: originalSize.height * Constants.smallWidgetImageSizeRatio.height)
        }
    }
    
}

extension WidgetAlarmsProvider: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        UserDefaults.appGroupSuite.lastLocation = locations.last
    }
}
