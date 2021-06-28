//
//  AudioBrowserViewController.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 11/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import BoldButton
import AWAlertController

protocol AudioBrowserViewControllerDelegate: AnyObject {
    func audio(didReturnTone controller: AudioBrowserViewController, soundName: String)
}

class AudioBrowserViewController: UIViewController {
    
    typealias ViewModel = AudioBrowserViewModel
    
    private let viewModel: ViewModel
    
    weak var delegate: AudioBrowserViewControllerDelegate?
    
    internal var tableView: UITableView! {
        didSet {
            tableView.register(TableHeaderView.self, forHeaderFooterViewReuseIdentifier: "header")
            tableView.register(SoundCell.self, forCellReuseIdentifier: "cell")
            tableView.dataSource = self
            tableView.delegate = self
        }
    }
    
    private lazy var buttonController: BoldButtonViewController = {
        let b = BoldButtonViewController()
        b.text = LocalizedStringKey.audio_playButtonTitle.localized
        b.delegate = self
        return b
    }()
    
    init(soundName: String) {
        viewModel = ViewModel(soundName: soundName)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = LocalizedStringKey.title_audio.localized
        setupView()
        viewModel.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.audio(didReturnTone: self, soundName: viewModel.selectedSoundName)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.pause()
    }
}

extension AudioBrowserViewController: AudioBrowserViewModelDelegate {
    func model(_ model: AudioBrowserViewModel, didChangeButtonLoadingStatus loading: Bool) {
        buttonController.isLoading = loading
    }
    
    func model(playerDidChangeStatus model: AudioBrowserViewModel, playing: Bool) {
        buttonController.text = (playing ? LocalizedStringKey.audio_pauseButtonTitle : .audio_playButtonTitle).localized
        buttonController.isSelected = !playing
    }
    
    func model(didReloadData model: AudioBrowserViewModel) {
        tableView.reloadData(animated: true)
    }
    
    func model(_ model: AudioBrowserViewModel, didChangeLoadingStatus loading: Bool, at indexPath: IndexPath) {
        
    }
}

extension AudioBrowserViewController: Drawerable {
    var drawerContentViewController: UIViewController? {
        return buttonController
    }
}

extension AudioBrowserViewController: BoldButtonViewControllerDelegate {
    func boldButtonPressed(_ sender: BoldButton) {
        viewModel.playbackButtonPressed()
    }
}

extension AudioBrowserViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(in: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SoundCell
        let model = viewModel.cellModel(at: indexPath)
        cell.configure(with: model)
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let enable = UnlockManager.unlocked || indexPath.section == 0
        cell.alpha = enable ? 1 : 0.4
        cell.isUserInteractionEnabled = enable
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return viewModel.footer(in: section)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch ViewModel.Section(rawValue: indexPath.section)! {
        case .sounds:
            tableView.reloadRows(at: [indexPath], with: .none)
        case .downloads:
            break
        }
        viewModel.didSelectRow(at: indexPath)
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
                AWAlertController.presentUnlockController(in: self) { _ in
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
}

extension AudioBrowserViewController: SoundCellDelegate {
    func soundCell(didPressDownloadButtonIn cell: SoundCell) {
        guard let path = tableView.indexPath(for: cell) else {
            return
        }
        cell.setLoading(true)
        viewModel.downloadSound(at: path)
    }
}

extension AudioBrowserViewController {
    func setupView() {
        let style: UITableView.Style
        if #available(iOS 13.0, *) {
            style = .insetGrouped
        } else {
            style = .grouped
        }
        tableView = UITableView(frame: .zero, style: style)
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

