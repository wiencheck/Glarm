//
//  CoreDataModel.swift
//  Glarm
//
//  Created by Adam Wienconek on 29/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import Foundation
import CoreDataManager

extension CoreDataModel {
    static let appModel = CoreDataModel(name: "Glarm", containerURL: SharedConstants.appGroupContainerURL, usesCloud: true)
}
