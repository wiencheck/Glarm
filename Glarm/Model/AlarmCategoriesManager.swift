//
//  AlarmCategoriesManager.swift
//  Glarm
//
//  Created by Adam Wienconek on 13/08/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import Foundation

final class AlarmCategoriesManager {
    private static let userDefaultsCategoriesKey = "AlarmCategories"
    
    var categories: (`default`: [String], custom: [String]) {
        return (defaultCategories.sorted(by: <),
                customCategories.sorted(by: <))
    }
    
    @discardableResult
    func addCategory(named name: String) -> Bool {
        if defaultCategories.contains(name) {
            return false
        }
        let result = customCategories.insert(name)
        return result.inserted
    }
    
    @discardableResult
    func removeCategory(named name: String) -> Bool {
        if defaultCategories.contains(name) {
            return false
        }
        return customCategories.remove(name) != nil
    }
}

private extension AlarmCategoriesManager {
    var defaultCategories: [String] {
        let localized: [LocalizedStringKey] = [
            .categories_work,
            .categories_school,
            .categories_travel
        ]
        return localized.map { $0.localized }
    }
    
    var customCategories: Set<String> {
        get {
            guard let arr = UserDefaults.standard.array(forKey: Self.userDefaultsCategoriesKey) as? [String] else {
                return []
            }
            return Set(arr)
        } set {
            let arr = Array(newValue)
            UserDefaults.standard.set(arr, forKey: Self.userDefaultsCategoriesKey)
        }
    }
}
