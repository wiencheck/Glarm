//
//  LocationManager.swift
//  Glarm
//
//  Created by Adam Wienconek on 14/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import CoreLocation

final class LocationManager: NSObject {
    static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    
    private(set) var location: CLLocation?
    
    private override init() {
        super.init()
        manager.delegate = self
    }
    
    deinit {
        stop()
    }
    
    func start() {
        manager.startUpdatingLocation()
    }
    
    func stop() {
        manager.stopUpdatingLocation()
    }
    
    func distance(from location: CLLocation) -> CLLocationDistance {
        let distance = self.location?.distance(from: location) ?? 0
        return distance
    }
    
    func distance(from coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let distance = self.location?.distance(from: CLLocation(coordinate: coordinate)) ?? 0
        return distance
    }
    
    private var onLocationAuthorizationStatusChange: ((AuthorizationStatus) -> Void)?
    func requestAuthorization(completion: @escaping (AuthorizationStatus) -> Void) {
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = manager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        
        switch status {
        case .notDetermined:
            onLocationAuthorizationStatusChange = completion
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            completion(.authorized)
        default:
            completion(.resticted)
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        location = locations.last
        onLocationAuthorizationStatusChange?(.authorized)
        onLocationAuthorizationStatusChange = nil
        UserDefaults.appGroupSuite.lastLocation = locations.last
    }
    
    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            return
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            onLocationAuthorizationStatusChange?(.resticted)
            onLocationAuthorizationStatusChange = nil
        }
    }
}
