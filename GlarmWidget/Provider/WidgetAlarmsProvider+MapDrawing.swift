//
//  WidgetAlarmEntry+MapDrawing.swift
//  Glarm
//
//  Created by Adam Wienconek on 29/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import Foundation
import MapKit

extension WidgetAlarmsProvider {
    func createImage(locationInfo: LocationNotificationInfo, userLocation: CLLocation?, size: CGSize, completion: @escaping (UIImage?) -> Void) {
        let coordinates: [CLLocationCoordinate2D] = [userLocation?.coordinate, locationInfo.coordinate].compactMap { $0
        }
        
//        if var maxCoordinate = coordinates.max(by: {
//            $0.longitude > $1.longitude
//        }) {
//            maxCoordinate.longitude *= 1.4
//            coordinates.append(maxCoordinate)
//        }
        
        createSnapshot(fromCoordinates: coordinates,
                       withSize: size) { snapshot in
            guard let snapshot = snapshot else {
                completion(nil)
                return
            }
            var distance = CLLocationDistance(0)
            if let userLocation = userLocation {
                distance = CLLocation(coordinate: locationInfo.coordinate)
                    .distance(from: userLocation)
            }
            let modifiedImage = self.modifySnapshot(snapshot,
                                                    mapSpan: distance * 1.2,
                                                    destinationCoordinate: locationInfo.coordinate,
                                                    destinationRadius: locationInfo.radius,
                                                    userCoordinate: userLocation?.coordinate,
                                                    destinationName: locationInfo.name)
            completion(modifiedImage)
        }
    }
    
    private func createSnapshot(fromCoordinates coordinates: [CLLocationCoordinate2D], withSize size: CGSize = CGSize(width: 256, height: 256), traitCollection: UITraitCollection? = nil, completion: @escaping (MKMapSnapshotter.Snapshot?) -> Void) {
        let options = MKMapSnapshotter.Options()
        
        /* Set snapshotter options */
        options.region = MKCoordinateRegion(coordinates: coordinates, spanMultiplier: 1.2)
        options.size = size
        options.pointOfInterestFilter = .excludingAll
        if let traitCollection = traitCollection {
            options.traitCollection = UITraitCollection(traitsFrom: [
                options.traitCollection,
                traitCollection
            ])
        }
        
        /* Run snapshotter */
        MKMapSnapshotter(options: options)
            .start { snapshot, error in
                if let error = error {
                    print("*** Couldn't create map snapshot, error: \(error)")
                }
                completion(snapshot)
        }
    }
    
    private func modifySnapshot(_ snapshot: MKMapSnapshotter.Snapshot, mapSpan: CLLocationDistance, tintColor: UIColor? = nil, overlayAlpha: CGFloat = 0.4, destinationCoordinate: CLLocationCoordinate2D?, destinationRadius: CLLocationDistance?, userCoordinate: CLLocationCoordinate2D?, destinationName: String?) -> UIImage {
        /* Extract image */
        let image = snapshot.image
        
        /* Calculate overlay size */
        var overlaySize: CGSize?
        if let radius = destinationRadius {
            var dimension = image.size.width
            /* To correctly calculate scale, we need to figure out if vertical distance is larger than horizontal. */
            if let destinationCoordinate = destinationCoordinate,
               let userCoordinate = userCoordinate {
                let verticalDistance = userCoordinate.latitude - destinationCoordinate.latitude
                let horizontalDistance = userCoordinate.longitude - destinationCoordinate.longitude
                if verticalDistance > horizontalDistance {
                    dimension = image.size.height
                }
            }
            
            /* Map span is necessary for calculating snapshot's scale. */
            let scale = dimension / CGFloat(mapSpan)
            let normalizedRadius = CGFloat(radius) * scale
            overlaySize = CGSize(width: normalizedRadius * 2,
                                 height: normalizedRadius * 2)
        }

        let renderer = UIGraphicsImageRenderer(size: image.size)
        let modifiedImage = renderer.image { context in
            /* Draw original image */
            image.draw(at: .zero)
            
            /* Draw circle over image */
            if let destinationCoordinate = destinationCoordinate,
               let overlaySize = overlaySize {
                /* Get destination point on snapshot image */
                let destinationPoint = snapshot.point(for: destinationCoordinate)
                
                self.drawDestinationOverlay(atPoint: destinationPoint,
                                            size: overlaySize,
                                            color: UIColor.tint.withAlphaComponent(SharedConstants.radiusOverlayAlpha),
                                            inContext: context.cgContext)
                
                /* Draw destination pin */
                self.drawPin(point: destinationPoint)
                
                /* Draw destination name */
                if false, let title = destinationName {
                    let attributes = self.titleAttributes()
                    
                    /* If title is too close to image's edge, offset it a bit */
                    let titleSize = title.size(withAttributes: attributes)
                    let titleOffset: CGFloat = 24
                    var titlePoint = destinationPoint
                    
                    /* Modify X position
                    1st case: title is near left edge
                    2nd case: title is too near right edge
                     */
                    if titlePoint.x - (titleSize.width / 2) <= 0 {
                        titlePoint.x += titleOffset
                    } else if titlePoint.x + (titleSize.width / 2) >= image.size.width {
                        titlePoint.x -= titleOffset
                    }
                    /* Modify Y position
                     1st case: title is near top edge
                     2nd case: title is too near bottom edge
                    */
                    if titlePoint.y - titleSize.height <= 0 {
                        titlePoint.y += titleOffset
                    } else if titlePoint.y + titleSize.height >= image.size.height {
                        titlePoint.y -= titleOffset
                    }
                    
                    self.drawTitle(title: title,
                                   atPoint: titlePoint,
                                   attributes: attributes)
                }
            }
            
            /* Draw user position */
            if let userCoordinate = userCoordinate {
                let userCenter = snapshot.point(for: userCoordinate)
                self.drawUserLocation(atPoint: userCenter, inContext: context.cgContext)
            }
            
        }
        return modifiedImage
    }
    
    private func drawDestinationOverlay(atPoint point: CGPoint, size: CGSize, color: UIColor, inContext context: CGContext) {
        
        /* Set overlay position and size */
        let overlayRect = CGRect(center: point, size: size)
        
        /* Set overlay color */
        color.setFill()
        
        /* Shenaningans */
        context.addEllipse(in: overlayRect)
        context.drawPath(using: .fill)
    }
    
    private func drawTitle(title: String, atPoint point: CGPoint, attributes: [NSAttributedString.Key: Any]) {
        let titleSize = title.size(withAttributes: attributes)
        
        title.draw(with: CGRect(
            x: point.x - titleSize.width / 2.0,
            y: point.y + 1,
            width: titleSize.width,
            height: titleSize.height),
                   options: .usesLineFragmentOrigin,
                   attributes: attributes,
                   context: nil)
    }

    private func titleAttributes() -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let titleFont = UIFont.systemFont(ofSize: 10, weight: UIFont.Weight.semibold)
        return [.font: titleFont,
                     .paragraphStyle: paragraphStyle]
    }
    
    private func drawPin(point: CGPoint) {
        let pinImage = UIImage(named: "mapPin")
        let size = CGSize(width: 34, height: 34)
        var rectangle = CGRect(center: point, size: size)
        rectangle.center.y -= (size.height / 2)
        pinImage?.draw(in: rectangle)
    }
    
    private func drawUserLocation(atPoint point: CGPoint, inContext context: CGContext) {
        let size = CGSize(width: 20, height: 20)
        
        /* Set overlay position and size */
        context.setStrokeColor(UIColor.userRing.cgColor)
        context.setLineWidth(3)
        context.setShadow(offset: CGSize(width: 1, height: 1), blur: 6)
        context.setFillColor(UIColor.tint.cgColor)
        
        let rectangle = CGRect(center: point, size: size)
        context.addEllipse(in: rectangle)
        context.drawPath(using: .fillStroke)
    }
}
