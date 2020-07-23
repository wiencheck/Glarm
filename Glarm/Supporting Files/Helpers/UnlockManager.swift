//
//  UnlockManager.swift
//  Glarm
//
//  Created by Adam Wienconek on 13/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit

/*
 Flow goes like this:
 - At app launch call determineFullAccess method, it will set the last installed version
 - Next time the method gets called it will present message saying that user is eligible for full version
 */

class UnlockManager {
    class var unlocked: Bool {
        if userIsEligible {
            return true
        }
        guard Config.appConfiguration == .release else {
            return true
        }
        return IAPHandler.shared.didPurchaseFullVersion
    }
    
    private static var userIsEligible = false
    
    class func determineFullAccess(application: UIApplication) {
        if unlocked {
            return
        }
        // Jeśli jest nil i są alerty w pamięci to miał pobrane 1.0
        // Stary klucz defaults był "alarms"
        guard application.lastInstalledAppVersion == nil,
            let _ = UserDefaults.standard.data(forKey: "alarms") else {
                userIsEligible = false
                return
        }
        userIsEligible = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let actions: [UIAlertAction] = [
                .cancel(text: "Cool"),
                UIAlertAction(localizedTitle: .donate_action, style: .default, handler: { _ in
                    AWAlertController.presentDonationController(in: application.keyWindow()?.rootViewController)
                })
            ]
            let model = AlertViewModel(localizedTitle: .unlock_eligibleTitle, message: .unlock_eligibleMessage, actions: actions, style: .alert)
            
            application.keyWindow()?.rootViewController?.present(AWAlertController(model: model), animated: true, completion: nil)
        }
    }
    
    class func unlock(completion: ((Error?) -> Void)?) {
        IAPHandler.shared.purchaseStatusBlock = { status in
            switch status {
            case .purchased:
                completion?(nil)
            case .failed(let error):
                completion?(error)
            }
            IAPHandler.shared.purchaseStatusBlock = nil
        }
        IAPHandler.shared.purchaseMyProduct(with: IAPHandler.FULL_VERSION_PRODUCT_ID)
    }
    
    class func restore(completion: ((Error?) -> Void)?) {
        IAPHandler.shared.purchaseStatusBlock = { status in
            switch status {
            case .purchased:
                completion?(nil)
            case .failed(let error):
                completion?(error)
            }
            IAPHandler.shared.purchaseStatusBlock = nil
        }
        IAPHandler.shared.restorePurchase()
    }
}
