//
//  AppDelegate.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 06/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import BoldButton

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UnlockManager.determineFullAccess(application: application)
        IAPHandler.shared.fetchAvailableProducts(completion: nil)
        LocationManager.shared.start()
        
        if #available(iOS 13.0, *) {
            // Use Scene Delegate
        } else {
            configureWindow()
        }
        customizeColors()
        
        application.launchCount += 1
        return true
    }

    private func configureWindow() {
        window = UIWindow()
        window!.rootViewController = RootController()
        window!.makeKeyAndVisible()
        window!.tintColor = .tint
    }
    
    private func customizeColors() {
        UINavigationBar.appearance().tintColor = .tint
        BoldButton.appearance().tintColor = .tint
    }
}
