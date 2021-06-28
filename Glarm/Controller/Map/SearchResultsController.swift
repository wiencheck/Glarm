//
//  SearchResultsController.swift
//  Glarm
//
//  Created by Adam Wienconek on 13/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import MapKit

protocol SearchResultsControllerDelegate: AnyObject {
    func searchResultsWillAppear()
    func searchResultsWillDisappear()
    func searchResults(didSelectLocation controller: SearchResultsController, name: String, address: String?, coordinate: CLLocationCoordinate2D)
}

final class SearchResultsController: UIViewController {
    var location: String?
    
    private var searchWork: DispatchWorkItem?
    
    private lazy var visualView: UIVisualEffectView = {
        let blurStyle: UIBlurEffect.Style
        if #available(iOS 13.0, *) {
            blurStyle = .systemMaterial
        } else {
            blurStyle = .regular
        }
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }()
    
    private lazy var tableView: UITableView = {
        let t = UITableView()
        t.dataSource = self
        t.delegate = self
        t.backgroundColor = .clear
        t.tableFooterView = UIView()
        return t
    }()
    
    private lazy var searchController: UISearchController = {
        let s = UISearchController()
        s.searchBar.placeholder = location ?? LocalizedStringKey.map_searchbarPlaceholder.localized
        s.obscuresBackgroundDuringPresentation = false
        s.hidesNavigationBarDuringPresentation = false
        s.searchBar.searchBarStyle = .minimal
        s.searchBar.isTranslucent = true
        s.searchBar.showsCancelButton = true
        s.delegate = self
        s.searchBar.delegate = self
        s.searchBar.keyboardType = UIKeyboardType.asciiCapable
        s.searchResultsUpdater = self
        return s
    }()
    
    weak var delegate: SearchResultsControllerDelegate?
    
//    private var items = [MapItem]() {
//        didSet {
//            tableView.reloadData()
//        }
//    }
    
    private var searchResults = [MKLocalSearchCompletion]()
    
    /// 500km
    private let regionRadius: CLLocationDistance = 500 * 1000
    
    private lazy var searchCompleter: MKLocalSearchCompleter = {
        let s = MKLocalSearchCompleter()
        s.delegate = self
        if #available(iOS 13.0, *) {
            s.resultTypes = [.address, .pointOfInterest]
        }
        let userCoordinate = LocationManager.shared.coordinate
        if userCoordinate != .zero {
            s.region = MKCoordinateRegion(center: userCoordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        }
        return s
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.titleView = searchController.searchBar
        searchController.searchBar.sizeToFit()
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { [weak self] notification in
            guard let self = self,
                let info = notification.userInfo, let value = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
                return
            }
            let converted = self.view.convert(value.cgRectValue, from: nil)
            let corrected = CGRect(origin: converted.origin, size: CGSize(width: converted.width, height: converted.height - self.view.safeAreaInsets.bottom))
            self.keyboardWillAppear(in: corrected)
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) { [weak self] _ in
            self?.keyboardWillDisappear()
        }
        
        setupView()
    }
    
    deinit {
        print(self, " deinit")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        delegate?.searchResultsWillAppear()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            self.searchController.searchBar.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.searchResultsWillDisappear()
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if searchController.isActive == true {
            searchController.searchBar.resignFirstResponder()
            searchController.dismiss(animated: flag) {
                super.dismiss(animated: flag, completion: completion)
            }
        } else {
            super.dismiss(animated: flag, completion: completion)
        }
    }
    
    internal func keyboardWillAppear(in frame: CGRect) {
        tableView.contentInset.bottom = frame.height
        if #available(iOS 11.1, *) {
            tableView.verticalScrollIndicatorInsets.bottom = frame.height
        } else {
            tableView.scrollIndicatorInsets.bottom = frame.height
        }
    }
    
    internal func keyboardWillDisappear() {
        tableView.contentInset.bottom = 0
        if #available(iOS 11.1, *) {
            tableView.verticalScrollIndicatorInsets.bottom = 0
        } else {
            tableView.scrollIndicatorInsets.bottom = 0
        }
    }
    
    private func performSearchRequest(with query: String) {
        searchCompleter.cancel()
        searchCompleter.queryFragment = query
    }
    
    private func geocodeLocation(address: String, completion: @escaping (CLPlacemark) -> Void) {
        var region: CLCircularRegion?
        if LocationManager.shared.coordinate != .zero {
            region = CLCircularRegion(center: LocationManager.shared.coordinate, radius: regionRadius, identifier: address)
        }
        CLGeocoder().geocodeAddressString(address, in: region, preferredLocale: nil) { placemarks, _ in
            guard let placemark = placemarks?.first else {
                return
            }
            completion(placemark)
        }
    }
}

extension SearchResultsController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        tableView.reloadData()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        
    }
}

extension SearchResultsController: UISearchResultsUpdating {
    internal func updateSearchResults(for searchController: UISearchController) {
//        searchWork?.cancel()
        guard let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !query.isEmpty else {
            return
        }
        performSearchRequest(with: query)
//        searchWork = DispatchWorkItem {
//            self.performSearchRequest(with: query)
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: searchWork!)
    }
}

extension SearchResultsController: UISearchControllerDelegate {

}

extension SearchResultsController: UISearchBarDelegate {
    internal func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismiss(animated: true, completion: nil)
    }
}

extension SearchResultsController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        }
        
        let item = searchResults.at(indexPath.row)
        cell.textLabel?.text = item?.title
        cell.detailTextLabel?.text = item?.subtitle
        cell.backgroundColor = .clear
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let item = searchResults.at(indexPath.row) else {
            return
        }
        let address = [item.title, item.subtitle].joined(separator: ", ")
        geocodeLocation(address: address) { placemark in
            guard let coordinate = placemark.location?.coordinate else {
                return
            }
            self.delegate?.searchResults(didSelectLocation: self, name: item.title, address: placemark.locality, coordinate: coordinate)
        }
    }
}

extension SearchResultsController {
    private func setupView() {
        view.addSubview(visualView)
        visualView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
