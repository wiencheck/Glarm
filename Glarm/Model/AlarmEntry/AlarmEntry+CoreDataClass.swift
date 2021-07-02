//
//  AlarmEntry+CoreDataClass.swift
//  Glarm
//
//  Created by Adam Wienconek on 21/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//
//

import Foundation
import CoreData
import CoreDataManager
import UserNotifications

@objc(AlarmEntry)
public class AlarmEntry: NSManagedObject, AlarmEntryProtocol {
    var isActive = false
    
//    func makeCopy() -> AlarmEntryProtocol {
//        let copy = AlarmEntry(entity: entity, insertInto: nil)
//        let properties = entity.properties.reduce(into: [String: Any]()) { dict, property in
//            dict[property.name] = value(forKey: property.name)
//        }
//        copy.setValuesForKeys(properties)
//        copy.isActive = isActive
//        
//        return copy
//    }
}

extension AlarmEntry: CoreDataRecord {
    public typealias Key = UUID
    
    public static var uniqueKeyPropertyName: String { "uuid" }
}
