//
//  AppDelegate.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 06/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import BoldButton
import ReviewKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private(set) static var shared: AppDelegate!

    private(set) lazy var alarmsManager = AlarmsManager()
    private(set) lazy var categoriesManager = AlarmCategoriesManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Self.shared = self
        
        IAPHandler.shared.fetchAvailableProducts(completion: nil)
        LocationManager.shared.start()
        alarmsManager.setup(in: application)
        categoriesManager.setup(in: application)
        
        setupAppReviewRules()
        customizeColors()
        
        application.launchCount += 1
        return true
    }
}

private extension AppDelegate {
    func setupAppReviewRules() {
        AppReviewManager.applicationiTunesIdentifier = "id1523237367"
        AppReviewManager.rules.numberOfActionsPerformed = 12
        // AppReviewManager.rules.isDebugging = true
    }
    
    func customizeColors() {
        UINavigationBar.appearance().tintColor = .tint
        BoldButton.appearance().tintColor = .tint
    }
}
