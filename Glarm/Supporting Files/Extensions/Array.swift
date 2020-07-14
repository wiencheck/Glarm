//
//  Array.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 06/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import Foundation

extension Array {
    func at(_ index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
