//
//  Sequence.swift
//  Glarm
//
//  Created by Adam Wienconek on 22/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import Foundation

extension Sequence {
    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>, ascending: Bool = true) -> [Element] {
        if ascending {
            return sorted { a, b in
                return a[keyPath: keyPath] < b[keyPath: keyPath]
            }
        } else {
            return sorted { a, b in
                return a[keyPath: keyPath] > b[keyPath: keyPath]
            }
        }
    }
}
