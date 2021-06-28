//
//  CategoriesViewModel.swift
//  Glarm
//
//  Created by Adam Wienconek on 13/08/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import Foundation

protocol CategoriesViewModelDelegate: AnyObject {
    func model(didReloadData model: CategoriesViewModel)
}

final class CategoriesViewModel {
    
    private let manager: AlarmCategoriesManagerProtocol
    private(set) var selectedCategory: Category?
    
    private(set) lazy var categories: [[Category]] = loadCategories()
    
    weak var delegate: CategoriesViewModelDelegate?

    init(category: Category?) {
        manager = AppDelegate.shared.categoriesManager
        self.selectedCategory = category
    }
    
    private func loadCategories() -> [[Category]] {
        var arr = Array<[Category]>(repeating: [], count: 2)
        for category in manager.categories.sorted(by: \.name) {
            if category.isCreatedByUser {
                arr[1].append(category)
            } else {
                arr[0].append(category)
            }
        }
        return arr.filter { !$0.isEmpty }
    }
    
    func createCategory(named name: String) {
        guard !name.isEmpty, UnlockManager.unlocked else {
            return
        }
        selectedCategory = manager.createCategory(named: name, imageName: nil)
        categories = loadCategories()
        delegate?.model(didReloadData: self)
    }
    
    func removeCategory(at path: IndexPath) -> Bool {
        let category = categories[path.section - 1][path.row]
        if let _ = manager.removeCategory(named: category.name) {
            return false
        }
        selectedCategory = nil
        categories = loadCategories()
        delegate?.model(didReloadData: self)
        return true
    }
}

// MARK: Table view stuff
extension CategoriesViewModel {
    private enum Section: Int, CaseIterable {
        case none
        case `default`
        case custom
    }
    
    var numberOfSections: Int {
        return categories.count + 1
    }
    
    func numberOfRows(in section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return categories[section - 1].count
    }
    
    func cellConfiguration(at path: IndexPath) -> (text: String, imageName: String?, selected: Bool)? {
        if path.section == 0 {
            return (.localized(.category_none), nil, selectedCategory == nil)
        }
        let category = categories[path.section - 1][path.row]
        return (category.name, category.imageName, category == selectedCategory)
    }
    
    func headerModel(in section: Int) -> TableHeaderView.Model? {
        switch Section(rawValue: section)! {
        case .none:
            return nil
        case .default:
            return .init(title: .localized(.category_defaultHeader), buttonTitle: UnlockManager.unlocked ? nil : .localized(.unlock))
        case .custom:
            return .init(title: .localized(.category_customHeader))
        }
    }
    
    func didSelectRow(at path: IndexPath) {
        selectedCategory = categories.at(path.section - 1)?[path.row]
        delegate?.model(didReloadData: self)
    }
    
    func canEditRow(at path: IndexPath) -> Bool {
        // Only custom section can be edited
        let category = categories[path.section - 1][path.row]
        return category.isCreatedByUser
    }
}

