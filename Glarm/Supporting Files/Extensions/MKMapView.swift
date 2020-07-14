//
//  MKMapView.swift
//  Glarm
//
//  Created by Adam Wienconek on 13/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import MapKit

extension MKMapView {
    func showUserLocation(and coordinate: CLLocationCoordinate2D, animated: Bool) {
        if let userCoordinate = CLLocationManager().location?.coordinate {
            let rect = MKMapRect(coordinates: [userCoordinate, coordinate])
            
            setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40), animated: true)
        } else {
            setCenter(coordinate, animated: true)
        }
    }
}
