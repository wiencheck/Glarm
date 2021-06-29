//
//  AlarmCategoriesManager.swift
//  Glarm
//
//  Created by Adam Wienconek on 13/08/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import Foundation
import CoreDataManager
import UIKit

final class AlarmCategoriesManager: CoreDatabaseManager<Category>, AlarmCategoriesManagerProtocol {
    
    var categories: [Category] {
        fetchAll() ?? []
    }
    
    override var dataModel: CoreDataModel {
        CoreDataModel(name: "Glarm", containerURL: nil, usesCloud: true)
    }
    
    override func setup(in application: UIApplication) {
        super.setup(in: application)
        if didLoadDefaultCategories {
            return
        }
        loadDefaultCategories()
    }
    
    func createCategory(named name: String, imageName: String?) -> Category? {
        let category = Category(name: name, imageName: imageName)
        guard insert(category) == nil else {
            return nil
        }
        return category
    }
    
    func removeCategory(named name: String) -> Error? {
        deleteOne(recordKey: name)
    }
    
    func assign(alarm: AlarmEntryProtocol, toCategory category: Category?) {
        guard let entry = alarm as? AlarmEntry else {
            fatalError()
        }
        if let oldCategory = entry.category {
            oldCategory.alarms.remove(entry)
        }
        entry.category = category
        category?.alarms.insert(entry)
    }
}
