//
//  AppRatingHelper.swift
//  Glarm
//
//  Created by Adam Wienconek on 14/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import StoreKit

class AppRatingHelper {
    private static let askInterval = 4
    private static var didAskInThisRuntime = false
    
    private init() {}
    
    private class var askCount: Int {
        get {
            return UserDefaults.standard.integer(forKey: "appLaunchCount")
        } set {
            UserDefaults.standard.set(newValue, forKey: "appLaunchCount")
        }
    }
    
    private static var shouldAskForReview: Bool {
        guard Config.appConfiguration == .release,
            askCount % askInterval == 0 else {
                return false
        }
        return true
    }
    
    class func askForReview() {
        if didAskInThisRuntime { return }
        defer {
            askCount += 1
        }
        guard shouldAskForReview else { return }
        SKStoreReviewController.requestReview()
    }
}
