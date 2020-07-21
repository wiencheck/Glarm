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
            
            let insets = UIEdgeInsets(top: safeAreaInsets.top + 100,
                                      left: safeAreaInsets.left + 100,
                                      bottom: safeAreaInsets.bottom + 100,
                                      right: safeAreaInsets.right + 100)
            setVisibleMapRect(rect, edgePadding: insets, animated: animated)
        }
    }
    
    var visibleDistance: CLLocationDistance {
        let westMapPoint = MKMapPoint(x: visibleMapRect.minX, y: visibleMapRect.midY)
        let eastMapPoint = MKMapPoint(x: visibleMapRect.maxX, y: visibleMapRect.midY)
        return westMapPoint.distance(to: eastMapPoint)
    }
}
