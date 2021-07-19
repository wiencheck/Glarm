//
//  SceneDelegate.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 06/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    private var rootController: RootController?
    
    private var appDelegate: AppDelegate? {
        UIApplication.shared.delegate as? AppDelegate
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)
        if let delegate = appDelegate {
            rootController = RootController(manager: delegate.alarmsManager)
            window!.rootViewController = rootController
        }
        window!.makeKeyAndVisible()
        window!.tintColor = .tint
        
        handleURLContexts(connectionOptions.urlContexts)
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        handleURLContexts(URLContexts)
    }
    
    private func handleURLContexts(_ contexts: Set<UIOpenURLContext>) {
        for context in contexts {
            let url = context.url
            switch url.scheme {
            case SharedConstants.newAlarmURLScheme:
                openEditView(withAlarm: nil)
            case SharedConstants.editAlarmURLScheme:
                let components = url
                    .absoluteString
                    .components(separatedBy: String.schemeAppendix)
                guard let last = components.last,
                      let key = UUID(uuidString: last) else {
                    break
                }
                let alarm = appDelegate?.alarmsManager.fetchOne(recordKey: key)
                openEditView(withAlarm: alarm)
            default:
                break
            }
        }
    }
    
    private func openEditView(withAlarm alarm: AlarmEntryProtocol?) {
        guard let browseVc = rootController?.navigation.viewControllers.first as? BrowseViewController else {
            return
        }
        browseVc.openEditView(withAlarm: alarm)
    }
}

