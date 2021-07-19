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
        guard let userCoordinate = LocationManager.shared.location?.coordinate else {
            setCenter(coordinate, animated: animated)
            return
        }
        
        if userCoordinate == .zero {
            setCenter(coordinate, animated: animated)
        } else if coordinate == .zero {
            setCenter(userCoordinate, animated: animated)
        } else {
            let region = regionThatFits(MKCoordinateRegion(coordinates: [userCoordinate, coordinate], spanMultiplier: SharedConstants.mapRegionSpanMultiplier))
            setRegion(region, animated: animated)
        }
    }
    
    var visibleDistance: CLLocationDistance {
        let westMapPoint = MKMapPoint(x: visibleMapRect.minX, y: visibleMapRect.midY)
        let eastMapPoint = MKMapPoint(x: visibleMapRect.maxX, y: visibleMapRect.midY)
        return westMapPoint.distance(to: eastMapPoint)
    }
    
    enum MapZoomScale {
        case small, medium, large
        
        fileprivate init(span: MKCoordinateSpan) {
            if span.latitudeDelta <= 0 {
                self = .small
            } else if span.latitudeDelta <= 2.5 {
                self = .medium
            } else {
                self = .large
            }
        }
    }
    
    var zoomScale: MapZoomScale { MapZoomScale(span: region.span) }
}
