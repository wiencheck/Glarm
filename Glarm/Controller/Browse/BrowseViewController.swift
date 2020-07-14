//
//  BrowseViewController.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 06/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import SnapKit
import BoldButton
import CoreLocation

final class BrowseViewController: UIViewController {
    internal var tableView: UITableView! {
        didSet {
            tableView.register(AlarmMapCell.self, forCellReuseIdentifier: "map")
            tableView.register(AlarmCell.self, forCellReuseIdentifier: "cell")
            tableView.backgroundView = EmptyBackgroundView(image: nil, top: LocalizedStringKey.emptyViewTitle.localized, bottom: LocalizedStringKey.emptyViewDetail.localized)
            tableView.dataSource = self
            tableView.delegate = self
            tableView.estimatedSectionFooterHeight = 0
            tableView.estimatedSectionHeaderHeight = 0
        }
    }
    
    private lazy var buttonController: BoldButtonViewController = {
        let b = BoldButtonViewController()
        b.text = LocalizedStringKey.createButtonTitle.localized
        b.delegate = self
        return b
    }()
    
    private lazy var barButtonItem = UIBarButtonItem(image: .info, style: .plain, target: self, action: #selector(barButtonPressed(_:)))
    
    let viewModel: BrowseViewModel
    
    init(model: BrowseViewModel) {
        viewModel = model
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = LocalizedStringKey.browserTitle.localized
        navigationItem.backBarButtonItem?.title = LocalizedStringKey.alarms.localized

        navigationItem.setRightBarButton(barButtonItem, animated: false)
        
        setupView()
        
        viewModel.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        for cell in tableView.visibleCells {
            guard let map = cell as? AlarmMapCell else {
                continue
            }
            map.endDisplayingUserLocation()
        }
    }
    
    private func openEditView(alarm: AlarmEntry?) {
        // Open edit view if alarm exists
        // Go straight to the map otherwise.
        let editModel = AlarmEditViewModel(manager: viewModel.manager, alarm: alarm)
        let editVc = AlarmEditController(model: editModel)
        guard alarm == nil else {
            navigationController?.pushViewController(editVc, animated: true)
            return
        }
        let mapVc = MapController(info: nil)
        mapVc.delegate = editModel
        let vcs = [self, editVc, mapVc]
        navigationController?.setViewControllers(vcs, animated: true)
    }
    
    @objc private func barButtonPressed(_ sender: UIBarButtonItem) {
        let actions: [UIAlertAction] = [
            UIAlertAction(localizedTitle: .leaveReview, style: .default, handler: { _ in
                UIApplication.shared.openReviewPage()
            }),
            UIAlertAction(localizedTitle: .messageMe, style: .default, handler: { _ in
                UIApplication.shared.openMail()
            }),
            UIAlertAction(localizedTitle: .openTips, style: .default, handler: { _ in
                let model = AlertViewModel(localizedTitle: .openTips, message: .tipsDescription, actions: [.cancel(text: LocalizedStringKey.dismiss.localized)], style: .alert)
                self.present(AWAlertController(model: model), animated: true, completion: nil)
            }),
            .cancel(text: LocalizedStringKey.dismiss.localized)
        ]
        let model = AlertViewModel(localizedTitle: .infoTitle, message: .infoDetail, actions: actions, style: .alert)
        present(AWAlertController(model: model), animated: true, completion: nil)
    }
}

extension BrowseViewController: Drawerable {
    var drawerContentViewController: UIViewController? {
        return buttonController
    }
}

extension BrowseViewController: BoldButtonViewControllerDelegate {
    func boldButtonPressed(_ sender: BoldButton) {
        openEditView(alarm: nil)
    }
}

extension BrowseViewController: BrowseViewModelDelegate {
    func model(didUpdate model: BrowseViewModel, scrollToTop: Bool) {
        DispatchQueue.main.async {
            self.tableView.reloadData(animated: true) { _ in
                let path = IndexPath(row: 0, section: 0)
                guard scrollToTop, self.tableView.validate(indexPath: path) else {
                    return
                }
                self.tableView.scrollToRow(at: path, at: .top, animated: false)
            }
        }
    }
    
    func model(didSelectEditAlarm model: BrowseViewModel, alarm: AlarmEntry) {
        DispatchQueue.main.async {
            self.openEditView(alarm: alarm)
        }
    }
    
    func model(didEncounterError model: BrowseViewModel, error: Error) {
        displayErrorMessage(title: nil, error: error)
    }
}

extension BrowseViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(in: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let model = viewModel.cellModel(for: indexPath)
        switch BrowseViewModel.Section(rawValue: indexPath.section)! {
        case .active:
            let cell = tableView.dequeueReusableCell(withIdentifier: "map", for: indexPath) as! AlarmMapCell
            cell.configure(with: model)
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! AlarmCell
            let model = viewModel.cellModel(for: indexPath)
            cell.configure(with: model)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.tableView(tableView, numberOfRowsInSection: section) > 0 ? viewModel.headerTitle(in: section) : nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.didSelectRow(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return viewModel.numberOfRows(in: section) > 0 ? 34 : .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let mapCell = cell as? AlarmMapCell else {
            return
        }
        mapCell.startDisplayingUserLocation()
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let mapCell = cell as? AlarmMapCell else {
            return
        }
        mapCell.endDisplayingUserLocation()
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        return viewModel.editingActions(at: indexPath)
    }
}

extension BrowseViewController {
    func setupView() {
        tableView = UITableView(frame: .zero, style: .grouped)
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

fileprivate extension UITableView {
    func validate(indexPath: IndexPath) -> Bool {
        if indexPath.section >= numberOfSections {
            return false
        }
        if indexPath.row >= numberOfRows(inSection: indexPath.section) {
            return false
        }
        return true
    }
}
