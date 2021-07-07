//
//  AlarmMapController.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 06/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import MapKit

protocol AlarmMapControllerDelegate: AnyObject {
    func map(didReturnLocationInfo controller: MapController, locationInfo: LocationNotificationInfo)
}

class MapController: UIViewController {
    
    /// Name, City
    private lazy var locationFullAddress = locationName
    func updateLocationName(name: String, city: String?, distance: CLLocationDistance) {
        // Avoid addresses like "Warszawa Centralna, Warszawa"
        if let city = city,
           !name.lowercased().contains(city.lowercased()) {
            locationFullAddress = [name, city].joined(separator: ", ")
        } else {
            locationFullAddress = name
        }
        if distance > 10 * 1000 {
            locationName = locationFullAddress
        } else {
            locationName = name
        }
    }
    
    var locationName: String {
        didSet {
            settingsController.locationName = locationName
        }
    }
    
    var coordinate: CLLocationCoordinate2D {
        didSet {
            annotation = MKPointAnnotation(coordinate: coordinate)
            annotation.title = locationName
            circle = MKCircle(center: coordinate, radius: radius)
        }
    }
    
    var radius: CLLocationDistance {
        didSet {
            circle = MKCircle(center: coordinate, radius: radius)
        }
    }
    
    internal lazy var mapView: MKMapView = {
        let m = MKMapView()
        m.showsUserLocation = true
        m.pointOfInterestFilter = MKPointOfInterestFilter(including: [])
        m.showsScale = true
        m.addGestureRecognizer(longPress)
        m.delegate = self
        return m
    }()
    
    private lazy var longPress: UILongPressGestureRecognizer = {
        let l = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        l.minimumPressDuration = 0.5
        return l
    }()
    
    private lazy var resultsController: SearchResultsController = {
        let s = SearchResultsController()
        s.delegate = self
        return s
    }()
    
    private lazy var settingsController: LocationSettingsController = {
        let s = LocationSettingsController(location: locationName, radius: radius)
        s.delegate = self
        return s
    }()
    
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
    
    private var zoomChangedWork: DispatchWorkItem?
    
    weak var delegate: AlarmMapControllerDelegate?
    
    init(info: LocationNotificationInfo?) {
        locationName = info?.name ?? ""
        coordinate = info?.coordinate ?? .zero
        radius = info?.radius ?? .default
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = LocalizedStringKey.title_map.localized
        navigationItem.largeTitleDisplayMode = .never
        
        setupView()
        
        if coordinate == .zero {
            return
        }
        annotation = MKPointAnnotation(coordinate: coordinate)
        circle = MKCircle(center: coordinate, radius: radius)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mapView.showUserLocation(and: coordinate, animated: false)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let info = LocationNotificationInfo(name: locationName, coordinate: coordinate, radius: radius)
        delegate?.map(didReturnLocationInfo: self, locationInfo: info)
    }
    
    @objc private func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        let point = sender.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        geocode(coordinate: coordinate)
    }
    
    func geocode(coordinate: CLLocationCoordinate2D) {
        CLGeocoder().reverseGeocodeLocation(CLLocation(coordinate: coordinate)) { places, error in
            if let error = error {
                print("*** Couldn't geocode location: ", error.localizedDescription)
                return
            }
            guard let place = places?.first else {
                return
            }
            let name = place.name ?? "Unknown place"
            self.updateLocationName(name: name, city: place.locality, distance: self.radius)
            self.coordinate = coordinate
        }
    }
}

extension MapController: Drawerable {
    var drawerContentViewController: UIViewController? {
        return settingsController
    }
}

extension MapController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let circle = overlay as? MKCircle else {
            return MKOverlayRenderer()
        }
        let renderer = MKCircleRenderer(circle: circle)
        renderer.fillColor = .tint
        renderer.alpha = SharedConstants.radiusOverlayAlpha
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "pin"
        var pav = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        if pav == nil {
            pav = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pav?.isDraggable = false
            pav?.canShowCallout = true
        } else {
            pav?.annotation = annotation
        }
        
        return pav
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        if (newState == .starting) {
            view.setDragState(.starting, animated: true)
        } else if newState == .ending || newState == .canceling {
            view.setDragState(.none, animated: true)
        }
        guard newState == .ending,
              let droppedCoordinate = view.annotation?.coordinate else { return }
        geocode(coordinate: droppedCoordinate)
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        zoomChangedWork?.cancel()
        zoomChangedWork = DispatchWorkItem {
            self.updateLocationName(name: self.locationFullAddress, city: nil, distance: mapView.visibleDistance)
            self.settingsController.mapZoomScale = mapView.zoomScale
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: zoomChangedWork!)
    }
}

extension MapController: LocationSettingsControllerDelegate, UIPopoverPresentationControllerDelegate {
    func searchBarPressed() {
        let nav = UINavigationController(rootViewController: resultsController)
        nav.modalPresentationStyle = .overFullScreen
        nav.modalTransitionStyle = .crossDissolve
        present(nav, animated: true, completion: nil)
    }
    
    func searchButtonPressed() {
        
    }
    
    func radiusChanged(_ radius: CLLocationDistance) {
        self.radius = radius
        //setRadius(radius, interactive: true)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

extension MapController: SearchResultsControllerDelegate {
    func searchResults(didSelectLocation controller: SearchResultsController, name: String, address: String?, coordinate: CLLocationCoordinate2D) {
        
        updateLocationName(name: name, city: address, distance: radius)
        self.coordinate = coordinate
        controller.dismiss(animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.mapView.showUserLocation(and: coordinate, animated: true)
        }
    }
    
    internal func searchResultsWillAppear() {
        UIView.animate(withDuration: 0.24) {
            self.navigationController?.navigationBar.alpha = 0
            self.drawer?.alpha = 0
        }
    }
    
    internal func searchResultsWillDisappear() {
        UIView.animate(withDuration: 0.24) {
            self.navigationController?.navigationBar.alpha = 1
            self.drawer?.alpha = 1
        }
    }
}

extension MapController {
    func setupView() {
        view.addSubview(mapView)
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
