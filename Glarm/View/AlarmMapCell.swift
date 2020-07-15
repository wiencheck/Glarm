//
//  AlarmMapCell.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 11/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import MapKit

class AlarmMapCell: UITableViewCell {
    static let preferredHeight: CGFloat = 180
    
    private var timer: Timer?
    
    private lazy var mapView: MKMapView = {
        let m = MKMapView()
        m.delegate = self
        m.isUserInteractionEnabled = false
        return m
    }()
    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.textColor = .label()
        l.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        return l
    }()
    
    private lazy var detailLabel: UILabel = {
        let l = UILabel()
        l.textColor = .secondaryLabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        return l
    }()
    
    private lazy var rightDetailLabel: UILabel = {
        let l = UILabel()
        l.textColor = .secondaryLabel()
        l.setContentHuggingPriority(.required, for: .vertical)
        l.font = .systemFont(ofSize: 14, weight: .regular)
        return l
    }()
    
    private lazy var indicatorView: UIImageView = {
        let i = UIImageView(image: .disclosure)
        i.tintColor = .gray
        i.contentMode = .scaleAspectFit
        return i
    }()
    
    private lazy var markedView: UIImageView = {
        let i = UIImageView(image: .star)
        i.contentMode = .scaleAspectFit
        return i
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        mapView.showsUserLocation = false
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    func configure(with model: AlarmCellViewModel?) {
        guard let model = model else {
            return
        }
        titleLabel.text = model.locationInfo.identifier
        radiusText = model.locationInfo.radius.readableRepresentation
        rightDetailLabel.text = model.date
        locationInfo = model.locationInfo
        if let marked = model.marked {
            markedView.isHidden = !marked
        } else {
            markedView.isHidden = true
        }
    }
    
    private func updateDetailText() {
        guard let text = radiusText,
           let info = locationInfo else {
            return
        }
        let destination = CLLocation(coordinate: info.coordinate)
        let distance = LocationManager.shared.location.distance(from: destination)
        detailLabel.text = text + ", \(LocalizedStringKey.youAre.localized) \(distance.readableRepresentation) \(LocalizedStringKey.awayFromDestination.localized)"
    }
        
    func startDisplayingUserLocation() {
        mapView.showsUserLocation = true
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.updateDetailText()
        }
        timer?.tolerance = 10
    }
    
    func endDisplayingUserLocation() {
        mapView.showsUserLocation = false
        timer?.invalidate()
    }
}

private extension AlarmMapCell {
    func setupView() {
        addSubview(mapView)
        mapView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(mapView.snp.width).multipliedBy(0.44)
        }
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(mapView.snp.bottom).offset(6)
            make.leading.equalTo(layoutMarginsGuide)
        }
        
        addSubview(detailLabel)
        detailLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.bottom.equalTo(layoutMarginsGuide)
            make.leading.equalTo(titleLabel)
        }
        
        addSubview(indicatorView)
        indicatorView.snp.makeConstraints { make in
            make.top.equalTo(mapView.snp.bottom).offset(12)
            make.trailing.equalTo(layoutMarginsGuide)
            make.height.equalTo(indicatorView.snp.width)
            make.height.equalTo(10)
        }

        addSubview(rightDetailLabel)
        rightDetailLabel.snp.makeConstraints { make in
            make.centerY.equalTo(indicatorView)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(4)
            make.trailing.equalTo(indicatorView.snp.leading).offset(-2)
        }

        addSubview(markedView)
        markedView.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(detailLabel.snp.trailing).offset(8)
            make.trailing.equalTo(layoutMarginsGuide)
            make.top.equalTo(indicatorView.snp.bottom).offset(10)
            make.height.equalTo(markedView.snp.width)
            make.height.equalTo(12)
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

extension MKMapRect {
    init(coordinates: [CLLocationCoordinate2D]) {
        var rect = MKMapRect.null
        for coord in coordinates {
            let point = MKMapPoint(coord)
            rect = rect.union(MKMapRect(x: point.x, y: point.y, width: 0, height: 0))
        }
        self.init(origin: rect.origin, size: rect.size)
    }
}
