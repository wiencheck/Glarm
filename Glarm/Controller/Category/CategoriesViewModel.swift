//
//  CategoriesViewModel.swift
//  Glarm
//
//  Created by Adam Wienconek on 13/08/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import Foundation

protocol CategoriesViewModelDelegate: class {
    func model(didReloadData model: CategoriesViewModel)
}

final class CategoriesViewModel {
    
    private let manager: AlarmCategoriesManager
    private(set)var selectedCategory: String
    
    private var categories: [[String]] {
        return [
            [""],
            manager.categories.default,
            manager.categories.custom
        ]
    }
    
    weak var delegate: CategoriesViewModelDelegate?

    init(category: String) {
        manager = AlarmCategoriesManager()
        self.selectedCategory = category
    }
    
    func createCategory(named name: String) {
        guard manager.addCategory(named: name) else {
            return
        }
        if UnlockManager.unlocked {
            selectedCategory = name
        }
        delegate?.model(didReloadData: self)
    }
    
    func removeCategory(at path: IndexPath) -> Bool {
        let category = categories[path.section][path.row]
        guard manager.removeCategory(named: category) else {
            return false
        }
        if category == selectedCategory {
            selectedCategory = ""
        }
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
        return categories.count
    }
    
    func numberOfRows(in section: Int) -> Int {
        categories[section].count
    }
    
    func cellConfiguration(at path: IndexPath) -> (text: String, selected: Bool)? {
        let category = categories[path.section][path.row]
        let text = category.isEmpty ? LocalizedStringKey.category_none.localized : category
        return (text, category == selectedCategory)
    }
    
    func headerModel(in section: Int) -> TableHeaderView.Model? {
        switch Section(rawValue: section)! {
        case .none:
            return nil
        case .default:
            return .init(title: LocalizedStringKey.category_defaultHeader.localized, buttonTitle: UnlockManager.unlocked ? nil : .localized(.unlock))
        case .custom:
            if categories.last?.isEmpty == true {
                return nil
            }
            return .init(title: LocalizedStringKey.category_customHeader.localized)
        }
    }
    
    func didSelectRow(at path: IndexPath) {
        selectedCategory = categories[path.section][path.row]
        delegate?.model(didReloadData: self)
    }
    
    func canEditRow(at path: IndexPath) -> Bool {
        // Only custom section can be edited
        return path.section == 2
    }
}

