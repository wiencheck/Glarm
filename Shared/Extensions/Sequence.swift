//
//  Sequence.swift
//  Glarm
//
//  Created by Adam Wienconek on 22/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import Foundation

extension Sequence {
    
    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>, _ order: ComparisonResult = .orderedAscending) -> [Element] {
        switch order {
        case .orderedAscending:
            return sorted { a, b in
                return a[keyPath: keyPath] < b[keyPath: keyPath]
            }
        case .orderedDescending:
            return sorted { a, b in
                return a[keyPath: keyPath] > b[keyPath: keyPath]
            }
        default:
            return Array(self)
        }
    }
}
