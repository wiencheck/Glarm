//
//  AlarmMapController.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 06/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import MapKit

protocol AlarmMapControllerDelegate: class {
    func map(didReturnLocationInfo controller: MapController, locationInfo: LocationNotificationInfo)
}

class MapController: UIViewController {
    private var locationInfo: LocationNotificationInfo {
        didSet {
            if locationInfo.identifier != oldValue.identifier {
                settingsController.text = locationInfo.identifier
            }
            if locationInfo.coordinate != oldValue.coordinate {
                annotation = MKPointAnnotation(coordinate: locationInfo.coordinate)
                annotation.title = locationInfo.identifier
            }
            if locationInfo.coordinate != oldValue.coordinate || locationInfo.radius != oldValue.radius {
                circle = MKCircle(center: locationInfo.coordinate, radius: locationInfo.radius)
                
                let userLocation = LocationManager.shared.location
                if userLocation.coordinate == .zero {
                    return
                }
                let location = CLLocation(coordinate: locationInfo.coordinate)
                let offset: CLLocationDistance = 500
                settingsController.maximumValue = min(userLocation.distance(from: location) - offset, 150 * 1000)
            }
        }
    }
        
    internal lazy var mapView: MKMapView = {
        let m = MKMapView()
        m.showsUserLocation = true
        m.showsPointsOfInterest = true
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
        let s = LocationSettingsController()
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
    
    weak var delegate: AlarmMapControllerDelegate?
    
    init(info: LocationNotificationInfo?) {
        locationInfo = info ?? LocationNotificationInfo()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = LocalizedStringKey.mapTitle.localized
        navigationItem.largeTitleDisplayMode = .never

        settingsController.text = locationInfo.identifier
        settingsController.radius = locationInfo.radius
        setupView()
        
        let region = MKCoordinateRegion(center: LocationManager.shared.coordinate, latitudinalMeters: CLLocationDistance.default * 3, longitudinalMeters: CLLocationDistance.default * 3)
        mapView.setRegion(region, animated: false)
        
        if locationInfo == .default {
            return
        }
        annotation = MKPointAnnotation(coordinate: locationInfo.coordinate)
        circle = MKCircle(center: locationInfo.coordinate, radius: locationInfo.radius)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mapView.showUserLocation(and: locationInfo.coordinate, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.map(didReturnLocationInfo: self, locationInfo: locationInfo)
    }
    
    @objc private func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        let point = sender.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) { places, error in
            if let error = error {
                print("*** Couldn't geocode location: ", error.localizedDescription)
                return
            }
            guard let place = places?.first else {
                
                return
            }
            self.locationInfo.identifier = place.locality ?? "Unknown"
            self.locationInfo.coordinate = coordinate
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
        renderer.alpha = 0.4
        return renderer
    }
}

extension MapController: LocationSettingsControllerDelegate {
    func searchBarPressed() {
        let nav = UINavigationController(rootViewController: resultsController)
        nav.modalPresentationStyle = .overFullScreen
        nav.modalTransitionStyle = .crossDissolve
        present(nav, animated: true, completion: nil)
    }
    
    func searchButtonPressed() {
        
    }
    
    func sliderChanged(value: Double) {
        locationInfo.radius = value
    }
}

extension MapController: SearchResultsControllerDelegate {
    func searchResults(didSelectLocation controller: SearchResultsController, name: String, coordinate: CLLocationCoordinate2D) {
        locationInfo.identifier = name
        locationInfo.coordinate = coordinate
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

extension LocationSettingsController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        delegate?.searchBarPressed()
        return false
    }
}

extension MKPointAnnotation {
    convenience init(coordinate: CLLocationCoordinate2D) {
        self.init()
        self.coordinate = coordinate
    }
}

fileprivate protocol LocationSettingsControllerDelegate: class {
    func sliderChanged(value: Double)
    func searchBarPressed()
    func searchButtonPressed()
}

fileprivate class LocationSettingsController: UIViewController {
    private lazy var searchbarContainer = UIView()
    
    private lazy var sliderContainer = UIView()
    
    weak var delegate: LocationSettingsControllerDelegate?
    
    /// Radius in kilometers.
    var radius: CLLocationDistance = .default {
        didSet {
            slider.value = Float(radius)
            slider.isEnabled = true
        }
    }
    
    private let minimumValue: CLLocationDistance = 500
    var maximumValue: CLLocationDistance = 150 * 1000 {
        didSet {
            slider.maximumValue = Float(maximumValue)
        }
    }
    
    
    private lazy var radiusLabel: UILabel = {
        let l = UILabel()
        l.textColor = .label()
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.text = Double(slider.value).readableRepresentation
        l.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return l
    }()
    
    lazy var slider: UISlider = {
        let s = UISlider()
        s.minimumValue = Float(minimumValue)
        s.maximumValue = Float(maximumValue)
        s.value = Float(radius)
        s.isEnabled = false
        s.minimumTrackTintColor = .tint
        s.slideHandler = { [weak self] sender in
            self?.handleRadiusChanged(value: sender.value)
        }
        return s
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    private func handleRadiusChanged(value: Float) {
        let d = Double(value)
        delegate?.sliderChanged(value: d)
        radiusLabel.text = d.readableRepresentation
    }
    
    private func setupView() {
        let searchContainer = SettingView()
        searchContainer.title = LocalizedStringKey.choosePlacemark.localized
        
        searchContainer.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.equalTo(searchContainer.titleLabel.snp.leading).offset(8)
            make.top.equalTo(searchContainer.titleLabel.snp.bottom).offset(4).priority(.low)
            make.bottom.equalToSuperview().inset(8)
        }
        
        let sliderContainer = SettingView()
        sliderContainer.title = LocalizedStringKey.setDistance.localized
        
        sliderContainer.addSubview(slider)
        slider.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.equalTo(sliderContainer.titleLabel.snp.leading).offset(8)
            make.top.equalTo(sliderContainer.titleLabel.snp.bottom).offset(4).priority(.low)
        }
        
        sliderContainer.snp.makeConstraints { make in
            make.height.equalTo(100)
        }
        
        sliderContainer.addSubview(radiusLabel)
        radiusLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(slider.snp.bottom).offset(4)
        }
        
        let line = UIView()
        line.backgroundColor = UIColor.label().withAlphaComponent(0.07)
        line.snp.makeConstraints { make in
            make.height.equalTo(1)
        }
    
        let stack = UIStackView(arrangedSubviews: [searchContainer, line, sliderContainer])
        stack.axis = .vertical
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
      var text: String? {
          get {
              return searchBar.text
          } set {
              searchBar.text = newValue
          }
      }
      
      private lazy var searchBar: UISearchBar = {
          let s = UISearchBar()
        s.placeholder = LocalizedStringKey.searchLocationPlaceholder.localized
          s.searchBarStyle = .minimal
          s.delegate = self
          return s
      }()
}

fileprivate class SettingView: UIView {
    var title: String? {
        get {
            return titleLabel.text
        } set {
            titleLabel.text = newValue
        }
    }
    
    lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.setContentCompressionResistancePriority(.required, for: .vertical)
        l.setContentHuggingPriority(.required, for: .vertical)
        l.textColor = .secondaryLabel()
        l.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(8).priority(.required)
        }
    }
}
