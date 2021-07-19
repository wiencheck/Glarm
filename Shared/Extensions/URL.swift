//
//  URL.swift
//  Glarm
//
//  Created by Adam Wienconek on 22/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import Foundation

extension URL {
    var isLocal: Bool {
        return absoluteString.prefix(4) != "http"
    }
    
    init?(scheme: String) {
        self.init(string: scheme + "://")
    }
}
