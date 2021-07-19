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
import MapKit.MKMapView

protocol LocationSettingsControllerDelegate: AnyObject {
    var currentUnit: UnitLength { get }
    func radiusChanged(_ radius: CLLocationDistance)
    func radiusButtonPressed()
    func searchBarPressed()
    func searchButtonPressed()
}

extension LocationSettingsControllerDelegate {
    var currentUnit: UnitLength { UserDefaults.preferredUnitLength }
}

final class LocationSettingsController: UIViewController {
    private lazy var searchbarContainer = UIView()
    
    private lazy var sliderContainer = UIView()
    
    private var segmentFullDistances: [Double] = [] {
        didSet {
            updateSuggestedDistances()
        }
    }
    
    private var segmentTitles: [String] = []
    
    weak var delegate: LocationSettingsControllerDelegate?
    
    /// Current radius in kilometers.
    private(set)var radius: CLLocationDistance {
        didSet {
            radiusButton.text = radius.readableRepresentation(addingSymbol: false)
            delegate?.radiusChanged(radius)
        }
    }
    
    var locationName: String? {
        didSet {
            searchBar.text = locationName
        }
    }
    
    var mapZoomScale: MKMapView.MapZoomScale! {
        didSet {
            if oldValue == mapZoomScale { return }
            segmentFullDistances = makeSuggestedDistances(withZoomScale: mapZoomScale)
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
    
    private lazy var radiusButton: UIButton = {
        let l = BorderedButton()
        l.text = radius.readableRepresentation(addingSymbol: false)
        l.pressHandler = { [weak self] sender in
            self?.delegate?.radiusButtonPressed()
        }
        l.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return l
    }()
    
    private lazy var scrubbingDetailLabel: UILabel = {
        let l = UILabel()
        l.alpha = 0
        l.numberOfLines = 2
        l.textColor = .label()
        l.textAlignment = .center
        l.font = .subtitle
        l.text = LocalizedStringKey.edit_exactScrubbingMessage.localized
        l.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return l
    }()
    
    lazy var unitButton: UIButton = {
        let b = BorderedButton()
        b.text = delegate?.currentUnit.symbol
        b.menu = unitMenu
        b.showsMenuAsPrimaryAction = true
        return b
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
        segmentFullDistances = makeSuggestedDistances(withZoomScale: .large)
        setupView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        unlockButton.layer.cornerRadius = 12
    }
    
    private var segmentDistances: [CLLocationDistance] = []
    
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
}

extension LocationSettingsController {
    private func makeSuggestedDistances(withZoomScale scale: MKMapView.MapZoomScale) -> [Double] {
        switch scale {
        case .small:
            return [0.5, 1, 2, 4, 8]
        case .medium:
            return [2, 5, 10, 15, 20]
        case .large:
            return [5, 10, 15, 20, 25, 40]
        }
    }
    
    private func updateSuggestedDistances() {
        let unit = UserDefaults.preferredUnitLength
        var measurement = Measurement(value: 0, unit: unit)
        segmentDistances = segmentFullDistances.map { distance in
            print("Unit: \(distance) \(unit.symbol)")
            measurement.value = distance
            let meters = measurement.converted(to: .meters).value
            return meters
        }
        segmentTitles = segmentDistances.map { distance in
            distance.readableRepresentation(usingSpaces: false)
        }
        
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

extension LocationSettingsController: UnitMenuSelectable, RadiusInputHandling {
    func handleUnitChanged(from oldUnit: UnitLength, to unit: UnitLength) {
        updateSuggestedDistances()
        
        unitButton.text = unit.symbol
        // Resetting menu completely was necessary to fix the issue of correct state not being updated for actions.
        unitButton.menu = nil
        unitButton.menu = unitMenu
        
        guard let text = radiusButton.text,
              let input = translateInputToRadius(text, unit: unit) else {
            return
        }
        radius = input
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
        let container = SettingView()
        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        let searchContainer = SettingView()
        searchContainer.title = LocalizedStringKey.map_chooseDestination.localized
        
        searchContainer.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.equalTo(searchContainer.titleLabel).offset(-8)
            make.top.equalTo(searchContainer.titleLabel.snp.bottom).offset(2).priority(.low)
            make.bottom.equalToSuperview().inset(8)
        }
        
//        container.addSubview(searchBar, withTitle: .localized(.map_chooseDestination))
//        container.addSubview(distanceSegment, withTitle: .localized(.map_setRadius))
//        container.addSubview(slider, withTitle: nil)
 //       return ()
        
        let sliderContainer = SettingView()
        sliderContainer.title = LocalizedStringKey.map_setRadius.localized
        
        let radiusContainer = UIView()
        radiusContainer.backgroundColor = .clear
        
        let radiusDummyLabel = UILabel()
        radiusDummyLabel.text = "Radius"
        radiusDummyLabel.font = radiusButton.titleLabel?.font
        radiusDummyLabel.textColor = .secondaryLabel()
        radiusContainer.addSubview(radiusDummyLabel)
        radiusDummyLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview()
        }
        
        radiusContainer.addSubview(radiusButton)
        radiusButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(radiusDummyLabel.snp.trailing).offset(6)
        }
        
        unitButton.setContentHuggingPriority(.defaultHigh, for: .vertical)
        radiusContainer.addSubview(unitButton)
        unitButton.snp.makeConstraints { make in
            make.centerY.trailing.equalToSuperview()
        }
        
        let unitDummyLabel = UILabel()
        unitDummyLabel.text = "Units"
        unitDummyLabel.font = radiusButton.titleLabel?.font
        unitDummyLabel.textColor = .secondaryLabel()
        radiusContainer.addSubview(unitDummyLabel)
        unitDummyLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(unitButton.snp.leading).offset(-6)
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

fileprivate class SettingView2: UIView {
    private let stackSpacing: CGFloat = 12
    private let labelMargin: CGFloat = 8
    private let contentMargin: CGFloat = 16
    
    private lazy var stackView: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        //s.alignment = .
        s.spacing = stackSpacing
        return s
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
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(labelMargin)
            make.leading.equalToSuperview()
            make.center.equalToSuperview()
        }
    }
    
    func addSubview(_ view: UIView, withTitle title: String?) {
        if let title = title {
            if !stackView.arrangedSubviews.isEmpty {
                let separator = UIView()
                stackView.addArrangedSubview(separator)
                separator.snp.makeConstraints { make in
                    make.height.equalTo(1)
                    make.width.equalToSuperview()
                }
            }
            let label = UILabel()
            label.text = title
            label.font = .subtitle
            label.textColor = .secondaryLabel()
            stackView.addArrangedSubview(label)
            label.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(labelMargin)
            }
        }
        stackView.addArrangedSubview(view)
        view.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.equalToSuperview().offset(contentMargin)
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
            make.leading.equalToSuperview().offset(24)
        }
    }
}

extension LocationSettingsController: UISearchBarDelegate {
    internal func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        delegate?.searchBarPressed()
        return false
    }
}
