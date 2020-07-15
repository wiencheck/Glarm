//
//  AudioBrowserViewController.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 11/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import BoldButton

protocol AudioBrowserViewControllerDelegate: class {
    func audio(didReturnTone controller: AudioBrowserViewController, tone: AlarmTone)
}

class AudioBrowserViewController: UIViewController {
    
    private let viewModel: AudioBrowserViewModel
    
    weak var delegate: AudioBrowserViewControllerDelegate?
    
    internal var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
        }
    }
    
    private lazy var buttonController: BoldButtonViewController = {
        let b = BoldButtonViewController()
        b.text = LocalizedStringKey.playButtonTitle.localized
        b.delegate = self
        return b
    }()
    
    init(tone: AlarmTone) {
        viewModel = AudioBrowserViewModel(tone: tone)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = LocalizedStringKey.audioTitle.localized
        setupView()
        viewModel.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.audio(didReturnTone: self, tone: viewModel.selectedTone)
    }
}

extension AudioBrowserViewController: AudioBrowserViewModelDelegate {
    func model(playerDidChangeStatus model: AudioBrowserViewModel, playing: Bool) {
        buttonController.text = (playing ? LocalizedStringKey.pauseButtonTitle : .playButtonTitle).localized
        buttonController.isSelected = !playing
    }
    
    func model(didReloadData model: AudioBrowserViewModel) {
        tableView.reloadData()
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
        return viewModel.numberOfRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        let details = viewModel.cellDetails(at: indexPath)
        cell.textLabel?.text = details.0
        cell.accessoryType = details.1 ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return LocalizedStringKey.toneBrowserFooter.localized
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.didSelectRow(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
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

