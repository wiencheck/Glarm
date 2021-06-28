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
    
    private(set) var latitude: CLLocationDegrees = 0
    private(set) var longitude: CLLocationDegrees = 0
    
    private(set)var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        } set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
    
    var location: CLLocation {
        CLLocation(coordinate: coordinate)
    }
    
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
        let distance = self.location.distance(from: location)
        return distance
    }
    
    func distance(from coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let distance = self.location.distance(from: CLLocation(coordinate: coordinate))
        return distance
    }
    
    private var onLocationAuthorizationStatusChange: ((AuthorizationStatus) -> Void)?
    func requestAuthorization(completion: @escaping (AuthorizationStatus) -> Void) {
        switch CLLocationManager.authorizationStatus() {
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
        guard let location = manager.location else {
            return
        }
        coordinate = location.coordinate
        onLocationAuthorizationStatusChange?(.authorized)
        onLocationAuthorizationStatusChange = nil
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
