//
//  AlarmEditController.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 06/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import BoldButton
import AWAlertController

protocol AlarmEditControllerDelegate: AnyObject {
    func editController(_ controller: AlarmEditController, didDisappearWithoutSavingChanges modifiedAlarm: AlarmEntryProtocol)
}

final class AlarmEditController: UIViewController {

    typealias ViewModel = AlarmEditViewModel
    
    private let viewModel: ViewModel
    
    weak var delegate: AlarmEditControllerDelegate?
    
    internal lazy var tableView: UITableView = {
        let t = UITableView(frame: .zero, style: .grouped)
        t.register(EmptyLocationCell.self, forCellReuseIdentifier: "empty")
        t.register(NoteCell.self, forCellReuseIdentifier: "note")
        t.register(AlarmMapCell.self, forCellReuseIdentifier: "location")
        t.register(TableHeaderView.self, forHeaderFooterViewReuseIdentifier: "header")
        t.dataSource = self
        t.delegate = self
        t.estimatedSectionFooterHeight = 0
        t.estimatedSectionHeaderHeight = 0
        t.backgroundView = {
            let b = BackgroundTapView()
            b.backgroundColor = .clear
            b.delegate = self
            return b
        }()
        return t
    }()
    
    private lazy var buttonController: BoldButtonViewController = {
        let b = BoldButtonViewController()
        b.text = viewModel.scheduleButtonTitle
        b.delegate = self
        return b
    }()
    
    private lazy var markBarButton = UIBarButtonItem(image: .star(filled: viewModel.alarm.isMarked), style: .plain, target: self, action: #selector(handleMarkButtonPressed(_:)))
    
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
        navigationItem.backBarButtonItem = UIBarButtonItem(title: LocalizedStringKey.edit_backButton.localized, style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = markBarButton

        setupView()
        viewModel.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        buttonController.isSelected = viewModel.scheduleButtonEnabled
        buttonController.isEnabled = viewModel.scheduleButtonEnabled
        markBarButton.isEnabled = viewModel.alarm.category == nil
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
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        guard parent == nil,
        viewModel.didMakeChanges,
            !viewModel.didSaveChanges else {
                return
        }
        delegate?.editController(self, didDisappearWithoutSavingChanges: viewModel.alarm)
    }
    
    private weak var noteHeader: TableHeaderView? {
        return tableView.headerView(forSection: ViewModel.Section.note.rawValue) as? TableHeaderView
    }
    
    @objc private func handleMarkButtonPressed(_ sender: UIBarButtonItem) {
        let newStatus = !viewModel.alarm.isMarked
        viewModel.setAlarmMarked(newStatus)
        markBarButton.image = .star(filled: newStatus)
    }
    
    @objc private func handleRecurringSwitched(_ sender: UISwitch) {
        viewModel.setAlarmRepeating(sender.isOn)
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
    func model(didChangeButton model: AlarmEditViewModel) {
        DispatchQueue.main.async {
            self.buttonController.isSelected = model.scheduleButtonEnabled
            self.buttonController.isEnabled = model.scheduleButtonEnabled
        }
    }
    
    func model(didSelectMap model: AlarmEditViewModel, locationInfo: LocationNotificationInfo?) {
        let vc = MapController(info: locationInfo)
        vc.delegate = viewModel
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func model(didSelectCategory model: AlarmEditViewModel, category: Category?) {
        let vc = CategoriesViewController(category: category)
        vc.delegate = viewModel
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func model(didSelectAudio model: AlarmEditViewModel, soundName: String) {
        let vc = AudioBrowserViewController(soundName: soundName)
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
        let section = ViewModel.Section(rawValue: indexPath.section)!
        switch section {
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
        case .category:
            let cell = tableView.dequeueReusableCell(withIdentifier: "category", style: .value1)
            var configuration = cell.defaultContentConfiguration()
            
            let category = viewModel.alarmCategory
            configuration.text = category?.name ?? .localized(.category_none)
            if let imageName = category?.imageName,
               let image = UIImage(systemName: imageName) {
                configuration.image = image
            } else {
                configuration.image = nil
            }
            cell.contentConfiguration = configuration
            cell.accessoryType = .disclosureIndicator
            
            return cell
        case .settings:
            let cell: UITableViewCell
            switch indexPath.row {
            case section.repeatsRow:cell = tableView.dequeueReusableCell(withIdentifier: "repeating", style: .default)
                cell.textLabel?.text = LocalizedStringKey.edit_repeatsCell.localized
                cell.accessoryView = {
                    let s = UISwitch()
                    s.addTarget(self, action: #selector(handleRecurringSwitched(_:)), for: .valueChanged)
                    s.isOn = viewModel.alarm.isRecurring
                    return s
                }()
            case section.soundRow:
                cell = tableView.dequeueReusableCell(withIdentifier: "audio", style: .value1)
                cell.textLabel?.text = LocalizedStringKey.edit_toneCell.localized
                cell.detailTextLabel?.text = viewModel.alarmToneName
                cell.accessoryType = .disclosureIndicator
            default:
                cell = tableView.dequeueReusableCell(withIdentifier: "cell", style: .default)
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 12
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
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

fileprivate protocol BackgroundTapViewDelegate: AnyObject {
    func backgroundView(didReceiveTouch view: BackgroundTapView)
}

fileprivate class BackgroundTapView: UIView {
    weak var delegate: BackgroundTapViewDelegate?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        delegate?.backgroundView(didReceiveTouch: self)
    }
}
