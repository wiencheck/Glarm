//
//  Config.swift
//  Glarm
//
//  Created by Adam Wienconek on 14/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import Foundation

struct Config {
    // This is private because the use of 'appConfiguration' is preferred.
    private static let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    
    // This can be used to add debug statements.
    private static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var appConfiguration: AppConfiguration {
        //    return .release
        if isDebug {
            return .debug
        } else if isTestFlight {
            return .test
        } else {
            return .release
        }
    }
    
    enum AppConfiguration: Int, CustomStringConvertible {
        case debug
        case test
        case release
        
        var description: String {
            switch self {
            case .debug:    return "Debug"
            case .test:     return "Test"
            case .release:   return "Release"
            }
        }
    }
}
