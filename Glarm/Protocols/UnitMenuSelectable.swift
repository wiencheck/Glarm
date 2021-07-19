//
//  UnitMenuSelectable.swift
//  Glarm
//
//  Created by Adam Wienconek on 19/07/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import UIKit

protocol UnitMenuSelectable: AnyObject {
    func handleUnitChanged(from oldUnit: UnitLength, to unit: UnitLength)
}

extension UnitMenuSelectable where Self: AnyObject {
    var currentUnit: UnitLength {
        get {
            UserDefaults.preferredUnitLength
        } set {
            let oldValue = currentUnit
            UserDefaults.preferredUnitLength = newValue
            handleUnitChanged(from: oldValue, to: newValue)
        }
    }
    
    var unitMenu: UIMenu {
        UIMenu(title: .localized(.unit_menuTitle),
               image: .download,
               identifier: .init("units"),
               options: [],
               children: unitMenuItems)
    }
    
    var units: [UnitLength] {
        [.kilometers, .miles]
    }
    
    private var unitMenuItems: [UIMenuElement] {
        return units.reversed().map { unit in
            let selected = unit == UserDefaults.preferredUnitLength
            print("\(unit.symbol) \(selected)")
            return UIAction(title: unit.localizedDescription,
                            discoverabilityTitle: unit.symbol,
                            state: selected ? .on : .off, handler: { [weak self] _ in
                self?.currentUnit = unit
            })
        }
    }
}
