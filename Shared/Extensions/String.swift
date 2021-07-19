//
//  String.swift
//  Glarm
//
//  Created by Adam Wienconek on 14/08/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import Foundation

extension String {
    static func localized(_ key: LocalizedStringKey) -> String {
        return key.localized
    }
    
    static let schemeAppendix: String = "://"
}

extension String: LocalizedError {
    public var errorDescription: String? { self }
}
