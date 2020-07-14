//
//  AWError.swift
//  Plum
//
//  Created by adam.wienconek on 09.11.2018.
//  Copyright © 2018 adam.wienconek. All rights reserved.
//

import Foundation

struct AWError: LocalizedError {
    private let description: String
    
    var errorDescription: String? {
        return description
    }
    
    init(description: String? = nil) {
        self.description = description ?? "Unknown Error"
    }
    
    init(error: Error) {
        self.description = error.localizedDescription
    }
}
