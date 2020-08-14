//
//  CategoriesViewController.swift
//  Glarm
//
//  Created by Adam Wienconek on 13/08/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import BoldButton

protocol CategoriesViewControllerDelegate: class {
    func categories(didReturnCategory controller: CategoriesViewController, category: String)
}

final class CategoriesViewController: UIViewController {
    typealias ViewModel = CategoriesViewModel

    // MARK: Private properties
    private let viewModel: ViewModel
    weak var delegate: CategoriesViewControllerDelegate?
        
    // MARK: UI elements
    private lazy var tableView: UITableView = {
        let style: UITableView.Style
        if #available(iOS 13.0, *) {
            style = .insetGrouped
        } else {
            style = .grouped
        }
        let t = UITableView(frame: .zero, style: style)
        t.register(TableHeaderView.self, forHeaderFooterViewReuseIdentifier: "header")
        t.delegate = self
        t.dataSource = self
        return t
    }()
    
    private lazy var buttonController: BoldButtonViewController = {
        let b = BoldButtonViewController()
        b.text = LocalizedStringKey.category_createButton.localized
        b.delegate = self
        return b
    }()
    
    init(category: String ) {
        viewModel = .init(category: category)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        viewModel.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.categories(didReturnCategory: self, category: viewModel.selectedCategory)
    }
}

// MARK: ViewModel delegate methods
extension CategoriesViewController: CategoriesViewModelDelegate {
    func model(didReloadData model: CategoriesViewModel) {
        DispatchQueue.main.async {
            self.tableView.reloadData(animated: true)
        }
    }
}

extension CategoriesViewController: Drawerable {
    var drawerContentViewController: UIViewController? {
        return buttonController
    }
}

extension CategoriesViewController: BoldButtonViewControllerDelegate {
    func boldButtonPressed(_ sender: BoldButton) {
        var alert: AWAlertController!
        let confirmAction = UIAlertAction(localizedTitle: .create, style: .default) { [weak self] _ in
            guard let text = alert.textFields?.first?.text else { return }
            self?.viewModel.createCategory(named: text)
        }
        confirmAction.isEnabled = false
        let model = AlertViewModel(localizedTitle: .category_createButton, message: .category_newCategoryMessage, actions: [confirmAction, .cancel()], style: .alert)
        alert = AWAlertController(model: model)
        alert.onTextFieldChange = { field in
            confirmAction.isEnabled = field.text?.isEmpty == false
        }
        alert.addTextField { field in
            field.placeholder = .localized(.category_newCategoryPlaceholder)
        }
        present(alert, animated: true, completion: nil)
    }
}

// MARK: UITableView delegate and datasource methods
extension CategoriesViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(in: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        let config = viewModel.cellConfiguration(at: indexPath)
        cell.textLabel?.text = config?.text
        cell.accessoryType = config?.selected == true ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let enable = UnlockManager.unlocked || indexPath.section == 0
        cell.alpha = enable ? 1 : 0.4
        cell.isUserInteractionEnabled = enable
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.didSelectRow(at: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
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
            AWAlertController.presentUnlockController(in: self) { _ in
                DispatchQueue.main.async {
                    tableView.reloadData(animated: true)
                }
            }
        }
        
        return header
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard viewModel.canEditRow(at: indexPath) else {
            return nil
        }
        let delete = UIContextualAction(style: .destructive, title: LocalizedStringKey.browse_deleteAction.localized) { [weak self] action, _, completion in
            let succ = self?.viewModel.removeCategory(at: indexPath) ?? false
            completion(succ)
        }
        let config = UISwipeActionsConfiguration(actions: [delete])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == tableView.numberOfSections else {
            return nil
        }
        return .localized(.category_footer)
    }
}

// MARK: Layout setup
private extension CategoriesViewController {
    func setupView() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
