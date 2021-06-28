//
//  NSManagedObject.swift
//  Glarm
//
//  Created by Adam Wienconek on 23/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import CoreData

extension NSManagedObject {
    func discardChanges() {
        managedObjectContext?.refresh(self, mergeChanges: false)
    }
}
