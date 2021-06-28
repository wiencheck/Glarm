//
//  LocationSettingsController.swift
//  Glarm
//
//  Created by Adam Wienconek on 19/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import CoreLocation
import AWAlertController

protocol LocationSettingsControllerDelegate: AnyObject {
    func radiusChanged(_ radius: CLLocationDistance)
    func searchBarPressed()
    func searchButtonPressed()
}

final class LocationSettingsController: UIViewController {
    private lazy var searchbarContainer = UIView()
    
    private lazy var sliderContainer = UIView()
    
    private var segmentDistances: [CLLocationDistance] = []
    
    weak var delegate: LocationSettingsControllerDelegate?
    
    /// Current radius in kilometers.
    private(set)var radius: CLLocationDistance {
        didSet {
            radiusLabel.text = radius.readableRepresentation()
            delegate?.radiusChanged(radius)
        }
    }
    
    var locationName: String? {
        didSet {
            searchBar.text = locationName
        }
    }
    
    private let minimumDistance: CLLocationDistance = 200
    // 100km
    private let maximumDistance: CLLocationDistance = 100 * 1000
    
    private lazy var searchBar: UISearchBar = {
        let s = UISearchBar()
        s.text = locationName
        s.placeholder = LocalizedStringKey.map_searchbarPlaceholder.localized
        s.searchBarStyle = .minimal
        s.delegate = self
        return s
    }()
    
    lazy var distanceSegment: UISegmentedControl = {
        let s = UISegmentedControl(items: segmentTitles)
        s.addTarget(self, action: #selector(distanceSegmentChanged(_:)), for: .valueChanged)
        s.isEnabled = UnlockManager.unlocked
        return s
    }()
    
    lazy var slider: UISlider = {
        let s = VariSlider()
        s.delegate = self
        s.doubleValue = radius / maximumDistance
        s.minimumTrackTintColor = .tint
        s.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        return s
    }()
    
    private lazy var radiusLabel: UILabel = {
        let l = UILabel()
        l.textColor = .label()
        l.textAlignment = .center
        l.font = .subtitle
        l.text = radius.readableRepresentation()
        l.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return l
    }()
    
    private lazy var scrubbingDetailLabel: UILabel = {
        let l = UILabel()
        l.alpha = 0
        l.numberOfLines = 2
        l.textColor = .label()
        l.textAlignment = .center
        l.font = .headerTitle
        l.text = LocalizedStringKey.edit_exactScrubbingMessage.localized
        l.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return l
    }()
    
    lazy var unitSegment: UISegmentedControl = {
        let units: [UnitLength] = [.meters, .miles]
        let s = UISegmentedControl(items: units.map{$0.symbol})
        s.selectedSegmentIndex = units.firstIndex(of: Locale.preferredUnitLength) ?? 0
        s.addTarget(self, action: #selector(unitSegmentChanged(_:)), for: .valueChanged)
        return s
    }()
    
    private lazy var unlockButton: UIButton = {
        let b = UIButton(type: .system)
        b.isHidden = UnlockManager.unlocked
        b.text = LocalizedStringKey.unlock.localized
        b.backgroundColor = .tint
        b.textColor = .white
        b.titleLabel?.font = .headerTitle
        b.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        b.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        b.pressHandler = { [weak self] sender in
            AWAlertController.presentUnlockController(in: self) { unlocked in
                sender.isHidden = unlocked
                self?.distanceSegment.isEnabled = unlocked
            }
        }
        return b
    }()
    
    init(location: String?, radius: CLLocationDistance = .default) {
        self.locationName = location
        self.radius = radius
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        unlockButton.layer.cornerRadius = 12
    }
    
    @objc private func sliderChanged(_ sender: UISlider) {
        if distanceSegment.isEnabled {
            distanceSegment.selectedSegmentIndex = UISegmentedControl.noSegment
        }
        let newRadius = (sender.doubleValue * maximumDistance)
        
        let rounded: Double
        if newRadius < 10 * 1000 {
            // Round to 100 meters
            rounded = newRadius.round(nearest: 100)
        } else if newRadius < 20 * 1000 {
            // Round to 500 meters
            rounded = newRadius.round(nearest: 500)
        } else if newRadius < 50 * 1000 {
            // Round to 1 km
            rounded = newRadius.round(nearest: 1000)
        } else {
            rounded = newRadius.round(nearest: 5000)
        }
        radius = rounded
        radiusLabel.text = rounded.readableRepresentation()
        delegate?.radiusChanged(rounded)
    }
    
    @objc private func distanceSegmentChanged(_ sender: UISegmentedControl) {
        guard let selectedTitle = sender.titleForSegment(at: sender.selectedSegmentIndex),
        let index = segmentTitles.firstIndex(of: selectedTitle) else {
            return
        }
        radius = segmentDistances[index]
        slider.setDoubleValue(radius / maximumDistance, animated: true)
    }
    
    @objc private func unitSegmentChanged(_ sender: UISegmentedControl) {
        guard let selectedTitle = sender.titleForSegment(at: sender.selectedSegmentIndex) else {
            return
        }
        Locale.preferredUnitLength = UnitLength(symbol: selectedTitle)
        radiusLabel.text = radius.readableRepresentation()
        updateSegmentTitles()
    }
}

extension LocationSettingsController {
    private var segmentTitles: [String] {
        return segmentDistances.map { distance in
            distance.readableRepresentation(usingSpaces: false)
        }
    }
    
    private func spitOutRadiusSuggestions(basedOn distance: Double, floor: Double) -> [Double] {
        let d: Double
        if distance > floor * 5 {
            d = (distance / 5).floor(nearest: floor)
        } else {
            d = (distance / 5).floor(nearest: floor / 5)
        }
        return [
            (d / 2).floor(nearest: 500),
            d, d*2, d*3, d*4
        ]
    }
    
    func updateDistanceFromLocation(_ distance: CLLocationDistance) {
        // Ensure it's at least 5km
        let adjustedDistance = max(5*1000, min(100*1000, distance.floor(nearest: 1)))
        let newDistances = spitOutRadiusSuggestions(basedOn: adjustedDistance, floor: 5000)
        
        // Avoid updating titles with same values
        if newDistances.last == segmentDistances.last {
            return
        }
        segmentDistances = newDistances
        updateSegmentTitles()
    }
    
    private func updateSegmentTitles() {
        UIView.transition(with: distanceSegment, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.distanceSegment.removeAllSegments()
            self.segmentTitles.reversed().forEach { title in
                self.distanceSegment.insertSegment(withTitle: title, at: 0, animated: false)
            }
        }, completion: { _ in
            guard self.distanceSegment.isEnabled else { return }
            if let index = self.segmentDistances.firstIndex(where: { $0 == self.radius }) {
                self.distanceSegment.selectedSegmentIndex = index
            }
        })
    }
}

extension LocationSettingsController: VariSliderDelegate {
    func slider(_ slider: VariSlider, scrubbingStatusChanged isScrubbing: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.distanceSegment.alpha = isScrubbing ? 0 : 1
            self.scrubbingDetailLabel.alpha = isScrubbing ? 1 : 0
        }
    }
}

private extension LocationSettingsController {
    func setupView() {
        let searchContainer = SettingView()
        searchContainer.title = LocalizedStringKey.map_chooseDestination.localized
        
        searchContainer.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.equalTo(searchContainer.titleLabel).offset(-8)
            make.top.equalTo(searchContainer.titleLabel.snp.bottom).offset(2).priority(.low)
            make.bottom.equalToSuperview().inset(8)
        }
        
        let sliderContainer = SettingView()
        sliderContainer.title = LocalizedStringKey.map_setRadius.localized
        
        let radiusContainer = UIView()
        radiusContainer.backgroundColor = .clear
        
        let radiusDummyLabel = UILabel()
        radiusDummyLabel.text = "Radius"
        radiusDummyLabel.font = radiusLabel.font
        radiusDummyLabel.textColor = .secondaryLabel()
        radiusContainer.addSubview(radiusDummyLabel)
        radiusDummyLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview()
        }
        
        radiusContainer.addSubview(radiusLabel)
        radiusLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(radiusDummyLabel.snp.trailing).offset(4)
        }
        
        unitSegment.setContentHuggingPriority(.defaultHigh, for: .vertical)
        radiusContainer.addSubview(unitSegment)
        unitSegment.snp.makeConstraints { make in
            make.centerY.trailing.equalToSuperview()
        }
        
        let unitDummyLabel = UILabel()
        unitDummyLabel.text = "Units"
        unitDummyLabel.font = radiusLabel.font
        unitDummyLabel.textColor = .secondaryLabel()
        radiusContainer.addSubview(unitDummyLabel)
        unitDummyLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(unitSegment.snp.leading).offset(-6)
        }
        
        let sliderStack: UIStackView = {
            let s = UIStackView(arrangedSubviews: [distanceSegment, slider, radiusContainer])
            s.axis = .vertical
            s.alignment = .center
            s.spacing = 18
            return s
        }()
        radiusContainer.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.width.equalToSuperview()
        }
        
        sliderContainer.insertSubview(sliderStack, belowSubview: distanceSegment)
        sliderStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.equalTo(sliderContainer.titleLabel)
            make.top.equalTo(sliderContainer.titleLabel.snp.bottom).offset(12)
            make.bottom.equalToSuperview().inset(10)
        }
        distanceSegment.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }
        slider.snp.makeConstraints { make in
            make.width.equalToSuperview().multipliedBy(0.98)
        }
        
        sliderContainer.addSubview(scrubbingDetailLabel)
        scrubbingDetailLabel.snp.makeConstraints { make in
            make.center.equalTo(distanceSegment)
            make.leading.equalTo(sliderContainer.titleLabel)
        }
        
        sliderContainer.addSubview(unlockButton)
        unlockButton.snp.makeConstraints { make in
            make.centerY.equalTo(sliderContainer.titleLabel)
            make.trailing.equalTo(distanceSegment)
            make.leading.greaterThanOrEqualTo(sliderContainer.titleLabel.snp.trailing).offset(12)
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
        l.font = .headerTitle
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
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(24).priority(.required)
        }
    }
}

extension LocationSettingsController: UISearchBarDelegate {
    internal func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        delegate?.searchBarPressed()
        return false
    }
}
