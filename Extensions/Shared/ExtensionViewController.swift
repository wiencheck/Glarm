//
//  ExtensionViewController.swift
//  Glarm
//
//  Created by Adam Wienconek on 06/08/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import SnapKit
import MapKit

protocol ExtensionViewControllerDelegate: AnyObject {
    func extensionController(_ controller: ExtensionViewController, didUpdateHeight newHeight: CGFloat)
}

final class ExtensionViewController: UIViewController {
    
    private var timer: Timer!
    
    /// Spacing between mapView-stack-bottom
    private let stackInterSpacing: CGFloat = 6
    
    private let shouldDisplayMap: Bool
    
    public weak var delegate: ExtensionViewControllerDelegate?
        
    private lazy var locationManager: CLLocationManager = {
        let l = CLLocationManager()
        l.delegate = self
        return l
    }()
    
    private var locationInfo: LocationNotificationInfo? {
        didSet {
            guard let mapView = mapView else {
                return
            }
            mapView.isHidden = locationInfo == nil
            guard let info = locationInfo else {
                mapView.removeAnnotations(mapView.annotations)
                mapView.removeOverlays(mapView.overlays)
                return
            }
            let annotation = MKPointAnnotation(coordinate: info.coordinate)
            mapView.addAnnotation(annotation)
            
            let circle = MKCircle(center: info.coordinate, radius: info.radius)
            mapView.addOverlay(circle)
        }
    }
    
    private lazy var mapView: MKMapView? = {
        guard shouldDisplayMap else {
            return nil
        }
        let m = MKMapView()
        m.tintColor = .tint
        m.delegate = self
        m.isUserInteractionEnabled = false
        return m
    }()
    
    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.font = .title
        l.textColor = .label()
        return l
    }()
    
    private lazy var detailLabel: UILabel = {
        let l = UILabel()
        l.font = .subtitle
        l.textColor = .secondaryLabel()
        return l
    }()
    
    /// Button for displaying note's content.
    private lazy var noteButton: UIButton = {
        let b = UIButton(type: .system)
        b.text = LocalizedStringKey.browse_showNote.localized
        b.textColor = .white
        b.backgroundColor = .tint
        b.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        b.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        b.pressHandler = { [weak self] _ in
            self?.showNote(true, animated: true)
        }
        b.titleLabel?.font = .subtitle
        return b
    }()
    
    private lazy var labelStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [titleLabel, detailLabel, noteButton])
        s.axis = .vertical
        s.alignment = .leading
        s.spacing = 8
        return s
    }()
    
    private lazy var noteHeader: UILabel = {
        let l = UILabel()
        l.text = LocalizedStringKey.edit_noteHeader.localized
        l.font = .headerTitle
        l.textColor = .secondaryLabel()
        return l
    }()
    
    /// Label displaying note's content.
    private lazy var noteLabel: UILabel = {
        let l = UILabel()
        l.font = .noteText
        l.textColor = .label()
        l.numberOfLines = 1
        // We hide the label so the stack will update its size when it becomes visible.
        //l.isHidden = true
        return l
    }()
    
    /// Button for hiding note label.
    private lazy var closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.text = LocalizedStringKey.dismiss.localized
        b.textColor = .white
        b.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        b.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        b.backgroundColor = .tint
        b.pressHandler = { [weak self] _ in
            self?.showNote(false, animated: true)
        }
        b.titleLabel?.font = .subtitle
        return b
    }()
    
    private lazy var noteStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [noteHeader, noteLabel, closeButton])
        s.axis = .vertical
        s.alignment = .leading
        s.spacing = 8
        s.alpha = 0
        return s
    }()
    
    init(shouldDisplayMap: Bool) {
        self.shouldDisplayMap = shouldDisplayMap
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.startUpdatingLocation()
        setupView()
        startDisplayingUserLocation()
    }
  
    // When this was enabled, location would only show on the first time when widget appeared.
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        startDisplayingUserLocation()
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        endDisplayingUserLocation()
//    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        [noteButton, closeButton].forEach {
            $0.layer.cornerRadius = 12
        }
        guard let coordinate = locationInfo?.coordinate else {
            return
        }
        showUserLocation(and: coordinate, animated: false)
    }
    
    public var contentHeight: CGFloat {
        if locationInfo == nil {
            return .leastNormalMagnitude
        }
        var height = (mapView?.bounds.height ?? 0) + (2 * stackInterSpacing)
        // Get visible stack.
        if let visibleStack = [noteStack, labelStack].first(where: { $0.alpha == 1 }) {
            height += visibleStack.bounds.height
        }
        return height
    }
    
    private func updateDetailText() {
        guard let info = locationInfo,
            info.coordinate != .zero,
            let userLocation = locationManager.location else {
                return
        }
        let destination = CLLocation(coordinate: info.coordinate)
        let distance = userLocation.distance(from: destination)
        detailLabel.text = info.radius.readableRepresentation() + ", \(LocalizedStringKey.notification_youAre.localized) \(distance.readableRepresentation()) \(LocalizedStringKey.notification_awayFromDestination.localized)"
    }
    
    public func configure(with alarm: AlarmEntryRepresentation) {
        guard let info = alarm.locationInfo else {
            return
        }
        titleLabel.text = info.name
        locationInfo = info
        updateDetailText()
        
        noteButton.isHidden = alarm.note.isEmpty
        noteLabel.text = alarm.note
        
        showUserLocation(and: info.coordinate, animated: false)
    }
    
    public func showNote(_ flag: Bool, animated: Bool) {
        UIView.animate(withDuration: animated ? 0.4 : 0, animations: {
            self.noteStack.alpha = flag ? 1 : 0
            self.labelStack.alpha = !flag ? 1 : 0
            self.mapView?.alpha = 1
            // Expand label and stack if needed.
            self.noteLabel.numberOfLines = 0
            self.view.layoutIfNeeded()
            self.delegate?.extensionController(self, didUpdateHeight: self.contentHeight)

        })
    }
}

extension ExtensionViewController: MKMapViewDelegate {
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

private extension ExtensionViewController {
    func setupView() {
        if let mapView = mapView {
            view.addSubview(mapView)
            mapView.snp.makeConstraints { make in
                make.leading.top.trailing.equalToSuperview()
                /// Compact height of widget.
                make.height.equalTo(110)
            }
        }
        
        view.addSubview(noteStack)
        noteStack.snp.makeConstraints { make in
            make.top.equalTo(mapView?.snp.bottom ?? view.snp.top).offset(stackInterSpacing)
            make.leading.equalToSuperview().offset(15)
            make.bottom.lessThanOrEqualToSuperview().inset(stackInterSpacing).priority(.low)
        }
        
        view.addSubview(labelStack)
        labelStack.snp.makeConstraints { make in
            make.top.equalTo(mapView?.snp.bottom ?? view.snp.top).offset(stackInterSpacing)
            make.leading.equalToSuperview().offset(15)
            make.bottom.lessThanOrEqualToSuperview().inset(stackInterSpacing).priority(.low)
        }
    }
    
    func showUserLocation(and coordinate: CLLocationCoordinate2D, animated: Bool) {
        guard let mapView = mapView else {
            return
        }
        let userCoordinate = locationManager.location?.coordinate ?? .zero
        
        if userCoordinate == .zero {
            mapView.setCenter(coordinate, animated: animated)
        } else if coordinate == .zero {
            mapView.setCenter(userCoordinate, animated: animated)
        } else {
            let region = mapView.regionThatFits(MKCoordinateRegion(coordinates: [userCoordinate, coordinate]))
            mapView.setRegion(region, animated: animated)
        }
    }
    
    func startDisplayingUserLocation() {
        mapView?.showsUserLocation = true
        updateDetailText()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.updateDetailText()
        }
        timer.tolerance = 10
    }
    
    func endDisplayingUserLocation() {
        mapView?.showsUserLocation = false
        timer?.invalidate()
    }
}

extension ExtensionViewController: CLLocationManagerDelegate {
    internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        updateDetailText()
    }
}
