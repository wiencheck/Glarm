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
import AWAlertController
import EmptyBackgroundView

final class BrowseViewController: UIViewController {
    internal lazy var tableView: AWTableView = {
        let t = AWTableView(frame: .zero, style: .grouped)
        t.register(AlarmMapCell.self, forCellReuseIdentifier: "map")
        t.register(AlarmCell.self, forCellReuseIdentifier: "alarm")
        t.register(TableHeaderView.self, forHeaderFooterViewReuseIdentifier: "header")
        t.backgroundView = EmptyBackgroundView(image: nil, top: LocalizedStringKey.emptyView_title.localized, bottom: LocalizedStringKey.emptyView_detail.localized)
        t.dataSource = self
        t.delegate = self
        t.estimatedSectionFooterHeight = 0
        t.estimatedSectionHeaderHeight = 0
        return t
    }()
    
    private lazy var buttonController: BoldButtonViewController = {
        let b = BoldButtonViewController()
        b.text = LocalizedStringKey.browse_createButtonTitle.localized
        b.delegate = self
        return b
    }()
    
    private lazy var unlockBarButtonItem = UIBarButtonItem(title: LocalizedStringKey.unlock_purchaseAction.localized, style: .plain, target: self, action: #selector(unlockBarButtonPressed(_:)))

    private lazy var aboutBarButtonItem = UIBarButtonItem(image: .info, style: .plain, target: self, action: #selector(aboutBarButtonPressed(_:)))
    
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
        navigationItem.title = LocalizedStringKey.title_browser.localized
        navigationItem.backBarButtonItem = UIBarButtonItem(title: LocalizedStringKey.browse_backButton.localized, style: .plain, target: nil, action: nil)

        if !UnlockManager.unlocked {
            navigationItem.setLeftBarButton(unlockBarButtonItem, animated: false)
            IAPHandler.purchasedProductIdentifiersChangedNotification.observe { sender in
                guard let iap = sender.object as? IAPHandler, iap.didPurchaseFullVersion else {
                    return
                }
                self.navigationItem.setLeftBarButton(nil, animated: true)
            }
        }
        navigationItem.setRightBarButton(aboutBarButtonItem, animated: false)
        
        setupView()
        
        viewModel.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadData()
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        #if DEBUG
            viewModel.manager.displayRandomAlarm()
        #endif
        guard shouldShowSwipeHint else {
            return
        }
        didShowSwipeHint = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.tableView.presentTrailingSwipeHint()
        }
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
    
    private var didShowSwipeHint = false
    
    private var shouldShowSwipeHint: Bool {
        if didShowSwipeHint ||
            tableView.isEmpty ||
            Self.swipeActionsUseCounter > 4 {
            return false
        }
        return UIApplication.shared.launchCount % 3 == 0
    }
    
    private func openEditView(withAlarm alarm: AlarmEntryProtocol?) {
        // Open edit view if alarm exists
        // Go straight to the map otherwise.
        let editModel = AlarmEditViewModel(manager: viewModel.manager, alarm: alarm)
        let editVc = AlarmEditController(model: editModel)
        editVc.navigationItem.backBarButtonItem = UIBarButtonItem(title: LocalizedStringKey.edit_backButton.localized, style: .plain, target: nil, action: nil)
        editVc.delegate = viewModel
        guard alarm == nil else {
            navigationController?.pushViewController(editVc, animated: true)
            return
        }
        let mapVc = MapController(info: nil)
        mapVc.delegate = editModel
        let vcs = [self, editVc, mapVc]
        navigationController?.setViewControllers(vcs, animated: true)
    }
    
    @objc private func unlockBarButtonPressed(_ sender: UIBarButtonItem) {
        AWAlertController.presentUnlockController(in: self)
    }
    
    @objc private func aboutBarButtonPressed(_ sender: UIBarButtonItem) {
        let actions: [UIAlertAction] = [
        UIAlertAction(localizedTitle: .donate_action, style: .default, handler: { [weak self] _ in
            AWAlertController.presentDonationController(in: self)
        }),
            UIAlertAction(localizedTitle: .about_leaveReview, style: .default, handler: { _ in
                UIApplication.shared.openReviewPage()
            }),
            UIAlertAction(localizedTitle: .about_messageMe, style: .default, handler: { _ in
                UIApplication.shared.openMail()
            }),
            UIAlertAction(localizedTitle: .about_helpLocalization, style: .default, handler: { _ in
                guard let str = PlistReader.property(from: PlistFile.urls.rawValue, key: "Translation") as? String, let url = URL(string: str), UIApplication.shared.canOpenURL(url) else {
                    return
                }
                UIApplication.shared.open(url)
            }),
            UIAlertAction(localizedTitle: .tips_title, style: .default, handler: { [weak self] _ in
                let model = AlertViewModel(localizedTitle: .tips_title, message: .tips_description, actions: [.cancel(text: LocalizedStringKey.dismiss.localized)], style: .alert)
                self?.present(AWAlertController(model: model), animated: true, completion: nil)
            }),
            .cancel(text: LocalizedStringKey.dismiss.localized)
        ]
        let model = AlertViewModel(localizedTitle: .about_title, message: .about_detail, actions: actions, style: .alert)
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
        viewModel.createPressed()
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
    
    func model(didSelectEditAlarm model: BrowseViewModel, alarm: AlarmEntryProtocol?) {
        DispatchQueue.main.async {
            self.openEditView(withAlarm: alarm)
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
        // First section contains active alarms
        let identifier = indexPath.section == 0 ? "map" : "alarm"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! AlarmCell
        let model = viewModel.cellModel(for: indexPath)
        cell.configure(with: model)
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let alarm = viewModel.alarm(at: indexPath)
        openEditView(withAlarm: alarm)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard self.tableView(tableView, numberOfRowsInSection: section) > 0 else {
            return nil
        }
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") as? TableHeaderView
        header?.title = viewModel.headerTitle(in: section)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return viewModel.numberOfRows(in: section) > 0 ? UITableView.automaticDimension : .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return TableHeaderView.preferredHeight
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
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let alarm = viewModel.alarm(at: indexPath) else {
            return nil
        }
        let isMarked = alarm.isMarked
        
        let action = UIContextualAction(style: .normal, title: isMarked ? .localized(.browse_unmarkAction) : .localized(.browse_markAction), handler: { [weak self] _, _, completion in
            self?.viewModel.markAlarm(atPath: indexPath, marked: !isMarked)
            completion(true)
        })
        action.backgroundColor = .tint
        
        let configuration = UISwipeActionsConfiguration(actions: [action])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let alarm = viewModel.alarm(at: indexPath) else {
            return nil
        }
        var actions: [UIContextualAction] = []
        
        if alarm.isActive {
            let cancel = UIContextualAction(style: .normal, title: LocalizedStringKey.cancel.localized, handler: { [weak self] _, _, completion in
                let success = self?.viewModel.cancelAlarm(at: indexPath) ?? false
                BrowseViewController.swipeActionsUseCounter += 1
                completion(success)
            })
            cancel.backgroundColor = .systemRed
            actions.append(cancel)
        } else {
            let delete = UIContextualAction(style: .destructive, title: LocalizedStringKey.browse_deleteAction.localized) { [weak self] _, _, completion in
                let success = self?.viewModel.deleteAlarm(at: indexPath) ?? false
                BrowseViewController.swipeActionsUseCounter += 1
                completion(success)
            }
            actions.append(delete)
            
            let schedule = UIContextualAction(style: .normal, title: LocalizedStringKey.browse_scheduleAction.localized, handler: { [weak self] _, _, completion in
                let success = self?.viewModel.scheduleAlarm(at: indexPath) ?? false
                BrowseViewController.swipeActionsUseCounter += 1
                completion(success)
            })
            schedule.backgroundColor = .purple
            actions.append(schedule)
        }
        let configuration = UISwipeActionsConfiguration(actions: actions)
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}

extension BrowseViewController {
    func setupView() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension BrowseViewController: AlarmCellDelegate {
    func alarmCell(didPressShowNote cell: AlarmCell) {
        guard let path = tableView.indexPath(for: cell),
            let model = viewModel.cellModel(for: path),
            let note = model.note else {
                return
        }
        let alertModel = AlertViewModel(title: model.locationInfo?.name, message: note, actions: [.dismiss], style: .alert)
        present(AWAlertController(model: alertModel), animated: true, completion: nil)
    }
}

extension BrowseViewController {
    class var swipeActionsUseCounter: Int {
        get {
            return UserDefaults.standard.integer(forKey: "swipeActionsUseCounter")
        } set {
            UserDefaults.standard.set(newValue, forKey: "swipeActionsUseCounter")
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
