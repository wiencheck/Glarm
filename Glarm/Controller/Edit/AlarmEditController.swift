//
//  AlarmEditController.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 06/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import BoldButton

final class AlarmEditController: UIViewController {
    let viewModel: AlarmEditViewModel
    
    internal var tableView: UITableView! {
        didSet {
            tableView.register(EmptyLocationCell.self, forCellReuseIdentifier: "empty")
            tableView.register(AlarmMapCell.self, forCellReuseIdentifier: "location")
            tableView.dataSource = self
            tableView.delegate = self
            tableView.estimatedSectionFooterHeight = 0
            tableView.estimatedSectionHeaderHeight = 0
        }
    }
    
    private lazy var buttonController: BoldButtonViewController = {
        let b = BoldButtonViewController()
        b.text = viewModel.scheduleButtonTitle
        b.delegate = self
        return b
    }()
    
    init(model: AlarmEditViewModel) {
        viewModel = model
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = LocalizedStringKey.editTitle.localized
        navigationItem.backBarButtonItem?.title = LocalizedStringKey.alarm.localized

        setupView()
        viewModel.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        buttonController.isSelected = viewModel.scheduleButtonEnabled
        buttonController.isEnabled = viewModel.scheduleButtonEnabled
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
}

extension AlarmEditController: Drawerable {
    var drawerContentViewController: UIViewController? {
        return buttonController
    }
}

extension AlarmEditController: BoldButtonViewControllerDelegate {
    func boldButtonPressed(_ sender: BoldButton) {
        viewModel.schedulePressed()
    }
}

extension AlarmEditController: AlarmEditViewModelDelegate {
    func model(didSelectMap model: AlarmEditViewModel, locationInfo: LocationNotificationInfo) {
        let vc = MapController(info: locationInfo)
        vc.delegate = viewModel
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func model(didSelectAudio model: AlarmEditViewModel, tone: AlarmTone) {
        let vc = AudioBrowserViewController(tone: tone)
        vc.delegate = viewModel
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func model(didReloadRow model: AlarmEditViewModel, at indexPath: IndexPath) {
        DispatchQueue.main.async {
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
    
    func model(didScheduleAlert model: AlarmEditViewModel, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                let model = AlertViewModel(title: "Couldn't schedule alert", message: error.localizedDescription, actions: [.cancel()], style: .alert)
                self.present(AWAlertController(model: model), animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}

extension AlarmEditController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(in: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch AlarmEditViewModel.Section(rawValue: indexPath.section)! {
        case .location:
            guard let model = viewModel.cellModel(for: indexPath) else {
                return tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath)
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "location", for: indexPath) as! AlarmMapCell
            cell.configure(with: model)
            return cell
        case .audio:
            var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "audio")
            if cell == nil {
                cell = UITableViewCell(style: .value1, reuseIdentifier: "audio")
            }
            cell.textLabel?.text = LocalizedStringKey.tone.localized
            cell.detailTextLabel?.text = viewModel.alarmToneName
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 34
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.headerTitle(in: section)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.didSelectRow(at: indexPath)
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
}

extension AlarmEditController {
    func setupView() {
        tableView = UITableView(frame: .zero, style: .grouped)
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
