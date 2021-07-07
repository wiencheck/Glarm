//
//  Unit.swift
//  Glarm
//
//  Created by Adam Wienconek on 07/07/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import Foundation

extension Unit {
    var localizedDescription: String {
        switch self {
        case UnitLength.kilometers:
            return .localized(.unit_kilometers)
        case UnitLength.miles:
            return .localized(.unit_miles)
        default:
            return symbol
        }
    }
}
