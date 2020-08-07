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

    typealias ViewModel = AlarmEditViewModel
    
    private let viewModel: ViewModel
    
    internal var tableView: UITableView! {
        didSet {
            tableView.register(EmptyLocationCell.self, forCellReuseIdentifier: "empty")
            tableView.register(NoteCell.self, forCellReuseIdentifier: "note")
            tableView.register(AlarmMapCell.self, forCellReuseIdentifier: "location")
            tableView.register(TableHeaderView.self, forHeaderFooterViewReuseIdentifier: "header")
            tableView.dataSource = self
            tableView.delegate = self
            tableView.estimatedSectionFooterHeight = 0
            tableView.estimatedSectionHeaderHeight = 0
            tableView.backgroundView = {
                let b = BackgroundTapView()
                b.backgroundColor = .clear
                b.delegate = self
                return b
            }()
        }
    }
    
    private lazy var buttonController: BoldButtonViewController = {
        let b = BoldButtonViewController()
        b.text = viewModel.scheduleButtonTitle
        b.delegate = self
        return b
    }()
    
    init(model: ViewModel) {
        viewModel = model
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = LocalizedStringKey.title_edit.localized
        navigationItem.backBarButtonItem?.title = LocalizedStringKey.edit_backButton.localized
        
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
            cell.endEditing(true)
            guard let map = cell as? AlarmMapCell else {
                continue
            }
            map.endDisplayingUserLocation()
        }
    }
    
    private weak var noteHeader: TableHeaderView? {
        return tableView.headerView(forSection: ViewModel.Section.note.rawValue) as? TableHeaderView
    }
}

extension AlarmEditController: Drawerable {
    var drawerContentViewController: UIViewController? {
        return buttonController
    }
    
    var shouldAdjustDrawerContentToKeyboard: Bool {
        return true
    }
}

extension AlarmEditController: BoldButtonViewControllerDelegate {
    func boldButtonPressed(_ sender: BoldButton) {
        viewModel.schedulePressed()
    }
}

extension AlarmEditController: AlarmEditViewModelDelegate {
    func model(didChangeButton model: AlarmEditViewModel) {
        DispatchQueue.main.async {
            self.buttonController.isSelected = model.scheduleButtonEnabled
            self.buttonController.isEnabled = model.scheduleButtonEnabled
        }
    }
    
    func model(didSelectMap model: AlarmEditViewModel, locationInfo: LocationNotificationInfo) {
        let vc = MapController(info: locationInfo)
        vc.delegate = viewModel
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func model(didSelectAudio model: AlarmEditViewModel, sound: Sound) {
        let vc = AudioBrowserViewController(sound: sound)
        vc.delegate = viewModel
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func model(didReloadSection model: AlarmEditViewModel, section: Int) {
        DispatchQueue.main.async {
            self.tableView.reloadSections([section], with: .fade)
        }
    }
    
    func model(didReloadRow model: AlarmEditViewModel, at indexPath: IndexPath) {
        DispatchQueue.main.async {
            self.tableView.reloadRows(at: [indexPath], with: .fade)
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
        switch ViewModel.Section(rawValue: indexPath.section)! {
        case .location:
            guard let model = viewModel.cellModel(for: indexPath) else {
                return tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath)
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "location", for: indexPath) as! AlarmMapCell
            cell.configure(with: model)
            return cell
        case .note:
            let cell = tableView.dequeueReusableCell(withIdentifier: "note") as! NoteCell
            cell.delegate = self
            cell.noteText = viewModel.alarmNoteText
            return cell
        case .audio:
            var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "audio")
            if cell == nil {
                cell = UITableViewCell(style: .value1, reuseIdentifier: "audio")
            }
            cell.textLabel?.text = LocalizedStringKey.edit_toneCell.localized
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
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return TableHeaderView.preferredHeight
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") as? TableHeaderView
        
        let model = viewModel.headerModel(in: section)
        header?.configure(with: model)
        header?.pressHandler = { _ in
            if model?.buttonTitle == LocalizedStringKey.unlock.localized {
                AWAlertController.presentUnlockController(in: self) { unlocked in
                    guard unlocked else { return }
                    DispatchQueue.main.async {
                        tableView.reloadSection(section, with: .fade)
                    }
                }
            } else {
                guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: section)) as? NoteCell else {
                    return
                }
                cell.clearText()
            }
        }
        
        return header
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard let noteCell = tableView.visibleCells.first(where: { $0 is NoteCell }) as? NoteCell else {
            return
        }
        noteCell.endEditing(true)
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
        cell.endEditing(true)
        guard let mapCell = cell as? AlarmMapCell else {
            return
        }
        mapCell.endDisplayingUserLocation()
    }
}

extension AlarmEditController: NoteCellDelegate {
    func noteCell(shouldBeginEditingTextIn cell: NoteCell) -> Bool {
        guard UnlockManager.unlocked else {
            AWAlertController.presentUnlockController(in: self)
            return false
        }
        guard let path = self.tableView.indexPath(for: cell) else {
            return false
        }
        DispatchQueue.main.async {
            self.tableView.scrollToRow(at: path, at: .middle, animated: true)
        }
        return true
    }
    
    func noteCell(didChangeTextIn cell: NoteCell) {
        viewModel.updateAlarmNote(text: cell.noteText)
        DispatchQueue.main.async {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
            self.noteHeader?.buttonTitle = self.viewModel.noteClearButtonText
        }
    }
}

extension AlarmEditController: BackgroundTapViewDelegate {
    fileprivate func backgroundView(didReceiveTouch view: BackgroundTapView) {
        guard let noteCell = tableView.visibleCells.first(where: { $0 is NoteCell }) as? NoteCell else {
            return
        }
        noteCell.endEditing(true)
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

fileprivate protocol BackgroundTapViewDelegate: class {
    func backgroundView(didReceiveTouch view: BackgroundTapView)
}

fileprivate class BackgroundTapView: UIView {
    weak var delegate: BackgroundTapViewDelegate?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        delegate?.backgroundView(didReceiveTouch: self)
    }
}
