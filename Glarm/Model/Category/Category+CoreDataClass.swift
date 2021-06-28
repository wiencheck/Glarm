//
//  Category+CoreDataClass.swift
//  Glarm
//
//  Created by Adam Wienconek on 23/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//
//

import Foundation
import CoreData
import CoreDataManager

@objc(Category)
public class Category: NSManagedObject {
    convenience init(name: String, imageName: String?) {
        self.init(entity: Self.entity(), insertInto: nil)
        self.name = name
        self.imageName = imageName
    }
}

extension Category: CoreDataRecord {
    public typealias Key = String
    
    public static var uniqueKeyPropertyName: String { "name" }
}

extension Category {
    class var `default`: Category {
        let category = Category(entity: entity(), insertInto: nil)
        category.name = ""
        category.isCreatedByUser = false
        return category
    }
}
