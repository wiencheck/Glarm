//
//  Category+CoreDataProperties.swift
//  Glarm
//
//  Created by Adam Wienconek on 23/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//
//

import Foundation
import CoreData

extension Category {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }

    @NSManaged public var name: String
    @NSManaged public var imageName: String?
    @NSManaged public var isCreatedByUser: Bool
    @NSManaged public var alarms: Set<AlarmEntry>

}

extension Category : Identifiable {

}
