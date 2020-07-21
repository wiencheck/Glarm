//
//  LocationSettingsController.swift
//  Glarm
//
//  Created by Adam Wienconek on 19/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import CoreLocation

protocol LocationSettingsControllerDelegate: class {
    func radiusChanged(_ radius: CLLocationDistance)
    func searchBarPressed()
    func searchButtonPressed()
}

final class LocationSettingsController: UIViewController {
    private lazy var searchbarContainer = UIView()
    
    private lazy var sliderContainer = UIView()
    
    private var segmentDistances: [CLLocationDistance] = [1000, 2000, 5000, 10000, 20000]
    
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
    // 150km
    private var maximumDistance: CLLocationDistance = 150 * 1000 {
        didSet {
            slider.setDoubleValue(radius / maximumDistance, animated: true)
        }
    }
    
    private lazy var searchBar: UISearchBar = {
        let s = UISearchBar()
        s.text = locationName
        s.placeholder = LocalizedStringKey.map_searchbarPlaceholder.localized
        s.searchBarStyle = .minimal
        s.delegate = self
        return s
    }()
    
    lazy var segment: UISegmentedControl = {
        let s = UISegmentedControl(items: segmentTitles)
        s.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        return s
    }()
    
    lazy var slider: UISlider = {
        let s = UISlider()
        s.doubleValue = radius / maximumDistance
        s.minimumTrackTintColor = .tint
        s.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        return s
    }()
    
    private lazy var radiusLabel: UILabel = {
        let l = UILabel()
        l.textColor = .label()
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.text = radius.readableRepresentation()
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
    
    @objc private func sliderChanged(_ sender: UISlider) {
        //segment.isSelected = false
        segment.selectedSegmentIndex = UISegmentedControl.noSegment
        radius = (sender.doubleValue * maximumDistance)
        radiusLabel.text = radius.readableRepresentation()
        delegate?.radiusChanged(radius)
    }
    
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
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
        let adjustedDistance = max(5*1000, min(150*1000, distance.floor(nearest: 1)))
        segmentDistances = spitOutRadiusSuggestions(basedOn: adjustedDistance, floor: 5000)
        
        // Avoid updating titles with same values
        guard let last = segmentDistances.last, last != maximumDistance else {
            return
        }
        updateSegmentTitles()
        maximumDistance = last
    }
    
    private func updateSegmentTitles() {
        UIView.transition(with: segment, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.segment.removeAllSegments()
            self.segmentTitles.reversed().forEach { title in
                self.segment.insertSegment(withTitle: title, at: 0, animated: false)
            }
        }, completion: { _ in
            if let index = self.segmentDistances.firstIndex(where: { $0 == self.radius }) {
                self.segment.selectedSegmentIndex = index
            }
        })
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
        
        radiusContainer.addSubview(unitSegment)
        unitSegment.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
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
            let s = UIStackView(arrangedSubviews: [segment, slider, radiusContainer])
            s.axis = .vertical
            s.alignment = .center
            s.spacing = 12
            return s
        }()
        radiusContainer.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.width.equalToSuperview()
        }
        
        sliderContainer.addSubview(sliderStack)
        sliderStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.equalTo(sliderContainer.titleLabel)
            make.top.equalTo(sliderContainer.titleLabel.snp.bottom).offset(12)
            make.bottom.equalToSuperview().inset(10)
        }
        segment.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }
        slider.snp.makeConstraints { make in
            make.width.equalToSuperview().multipliedBy(0.98)
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
            make.leading.top.equalToSuperview().offset(12).priority(.required)
        }
    }
}

extension LocationSettingsController: UISearchBarDelegate {
    internal func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        delegate?.searchBarPressed()
        return false
    }
}
