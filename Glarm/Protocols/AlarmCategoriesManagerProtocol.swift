//
//  AlarmCategoriesManagerProtocol.swift
//  Glarm
//
//  Created by Adam Wienconek on 24/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import Foundation
import CoreDataManager

protocol AlarmCategoriesManagerProtocol {
    var categories: [Category] { get }
    var didLoadDefaultCategories: Bool { get }
    func createCategory(named name: String, imageName: String?) -> Category?
    func removeCategory(named name: String) -> Error?
    func assign(alarm: AlarmEntryProtocol, toCategory category: Category?)
}

extension AlarmCategoriesManagerProtocol where Self: CoreDatabaseManager<Category> {
    var didLoadDefaultCategories: Bool {
        guard let randomName = defaultCategoryTemplates.randomElement()?.name,
              let _ = fetchOne(recordKey: randomName) else {
            return false
        }
        return true
    }
}

extension AlarmCategoriesManagerProtocol {
    private var keyStore: NSUbiquitousKeyValueStore {
        return NSUbiquitousKeyValueStore()
    }
    
    var didLoadDefaultCategories: Bool {
        get {
            return keyStore.bool(forKey: "didLoadDefaultCategories")
        } set {
            keyStore.set(newValue, forKey: "didLoadDefaultCategories")
            keyStore.synchronize()
        }
    }
    
    var defaultCategoryTemplates: [(name: String, imageName: String?)] {
        return [
            ("Travel", "airplane"),
            ("School", "text.book.closed"),
            ("Work", "building.2"),
            ("Family", "person.3.fill"),
            ("Short Distance", "bicycle"),
            ("Long Distance", "tram.fill"),
            ("Meetings", "figure.wave"),
            ("Training", "bolt.fill"),
            ("Food", "leaf.fill"),
            ("Shopping", "bag")
        ]
    }
    
    @discardableResult
    func loadDefaultCategories() -> Error? {
        for category in defaultCategoryTemplates.sorted(by: \.name) {
            if createCategory(named: category.name, imageName: category.imageName) == nil {
                return "Could not load default categories."
            }
        }
        return nil
    }
}
