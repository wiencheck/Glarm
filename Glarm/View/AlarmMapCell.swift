//
//  AlarmMapCell.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 11/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import MapKit

final class AlarmMapCell: AlarmCell {
    private var timer: Timer!
    
    private lazy var mapView: MKMapView = {
        let m = MKMapView()
        m.delegate = self
        m.isUserInteractionEnabled = false
        return m
    }()
    
    private var locationInfo: LocationNotificationInfo? {
        didSet {
            guard let info = locationInfo else {
                return
            }
            mapView.showUserLocation(and: info.coordinate, animated: false)
            if info.coordinate != oldValue?.coordinate {
                annotation = MKPointAnnotation(coordinate: info.coordinate)
            }
            if info.coordinate != oldValue?.coordinate || info.radius != oldValue?.radius {
                circle = MKCircle(center: info.coordinate, radius: info.radius)
            }
        }
    }
    private var radiusText: String? {
        didSet {
            detailLabel.text = radiusText
        }
    }
    
    private var annotation: MKPointAnnotation! {
        didSet {
            if let old = oldValue {
                mapView.removeAnnotation(old)
            }
            guard let new = annotation else { return }
            mapView.addAnnotation(new)
        }
    }
    
    private var circle: MKCircle! {
           didSet {
               if let old = oldValue {
                   mapView.removeOverlay(old)
               }
               guard let new = circle else { return }
               mapView.addOverlay(new)
           }
       }
    
    private var appStateObserver: Any?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        mapView.showsUserLocation = false
    }
    
    override func configure(with model: AlarmCell.Model?) {
        super.configure(with: model)
        guard let model = model else {
            return
        }
        radiusText = model.locationInfo.radius.readableRepresentation()
        locationInfo = model.locationInfo
    }
    
    private func updateDetailText() {
        guard let text = radiusText,
           let info = locationInfo,
            LocationManager.shared.coordinate != .zero else {
            return
        }
        let destination = CLLocation(coordinate: info.coordinate)
        let distance = LocationManager.shared.location.distance(from: destination)
        detailLabel.text = text + ", \(LocalizedStringKey.notification_youAre.localized) \(distance.readableRepresentation()) \(LocalizedStringKey.notification_awayFromDestination.localized)"
    }
        
    func startDisplayingUserLocation() {
        mapView.showsUserLocation = true
        updateDetailText()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.updateDetailText()
        }
        timer.tolerance = 10
        
        guard appStateObserver == nil else {
            return
        }
        appStateObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil, using: { [weak self] _ in
            self?.updateDetailText()
        })
    }
    
    func endDisplayingUserLocation() {
        mapView.showsUserLocation = false
        timer?.invalidate()
        
        guard let observer = appStateObserver else {
            return
        }
        NotificationCenter.default.removeObserver(observer, name: UIApplication.didBecomeActiveNotification, object: nil)
        appStateObserver = nil
    }
    
    override func setupView() {
        addSubview(mapView)
        mapView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(mapView.snp.width).multipliedBy(0.44)
        }
        
        let labelStack = UIStackView(arrangedSubviews: [titleLabel, detailLabel, noteButton])
        labelStack.axis = .vertical
        labelStack.spacing = 4
        addSubview(labelStack)
        labelStack.snp.makeConstraints { make in
            make.top.equalTo(mapView.snp.bottom).offset(8)
            make.leading.equalTo(layoutMarginsGuide)
            make.bottom.equalTo(layoutMarginsGuide)
        }
        
        addSubview(indicatorView)
        indicatorView.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalTo(layoutMarginsGuide)
            make.height.equalTo(indicatorView.snp.width)
            make.height.equalTo(10)
        }

        addSubview(rightDetailLabel)
        rightDetailLabel.snp.makeConstraints { make in
            make.centerY.equalTo(indicatorView)
            make.leading.greaterThanOrEqualTo(labelStack.snp.trailing).offset(4)
            make.trailing.equalTo(indicatorView.snp.leading).offset(-2)
        }
        
        addSubview(categoryLabel)
        categoryLabel.snp.makeConstraints { make in
            make.trailing.equalTo(layoutMarginsGuide)
            make.centerY.equalTo(detailLabel)
        }
        
        addSubview(categoryImageView)
        categoryImageView.snp.makeConstraints { make in
            make.height.equalTo(categoryImageView.snp.width)
            make.height.equalTo(16)
            make.leading.greaterThanOrEqualTo(detailLabel.snp.trailing).offset(2)
            make.trailing.equalTo(categoryLabel.snp.leading).offset(-2)
            make.centerY.equalTo(detailLabel)
        }
    }
}

extension AlarmMapCell: MKMapViewDelegate {
    internal func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let circle = overlay as? MKCircle else {
            return MKOverlayRenderer()
        }
        let renderer = MKCircleRenderer(circle: circle)
        renderer.fillColor = .tint
        renderer.alpha = 0.4
        return renderer
    }
}
