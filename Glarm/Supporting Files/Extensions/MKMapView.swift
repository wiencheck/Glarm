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
        let userCoordinate = LocationManager.shared.coordinate
        
        if userCoordinate == .zero {
            setCenter(coordinate, animated: animated)
        } else if coordinate == .zero {
            setCenter(userCoordinate, animated: animated)
        } else {
            let rect = MKMapRect(coordinates: [userCoordinate, coordinate])
            
            let insets = UIEdgeInsets(top: safeAreaInsets.top + 60,
                                      left: safeAreaInsets.left + 60,
                                      bottom: safeAreaInsets.bottom + 60,
                                      right: safeAreaInsets.right + 60)
            setVisibleMapRect(rect, edgePadding: insets, animated: true)
        }
    }
}
