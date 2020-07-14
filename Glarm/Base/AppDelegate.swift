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
        if #available(iOS 13.0, *) {
            // Use Scene Delegate
        } else {
            configureWindow()
        }
        customizeColors()
        window?.tintColor = .tint
        
        application.launchCount += 1
        return true
    }

    private func configureWindow() {
        window = UIWindow()
        window!.rootViewController = RootController()
        window!.makeKeyAndVisible()
    }
    
    private func customizeColors() {
        UINavigationBar.appearance().tintColor = .tint
        BoldButton.appearance().tintColor = .tint
    }
}
