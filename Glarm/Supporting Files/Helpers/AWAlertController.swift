//
//  AWAlertController.swift
//  Glarm
//
//  Created by Adam Wienconek on 13/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import AWAlertController

extension AWAlertController {
    
    class var notificationsPermissionRestrictedAlert: UIAlertController {
        let actions: [UIAlertAction] = [
            UIAlertAction(localizedTitle: .permission_openSettingsAction, style: .default, handler: { _ in
                UIApplication.shared.openSettings()
            }),
            .cancel()
        ]
        let model = AlertViewModel(title: .localized(.permission_notificationDeniedTitle), message: .localized(.permission_notificationDeniedMessage), actions: actions, style: .alert)
        return AWAlertController(model: model)
    }
    
    class func presentDonationController(in controller: UIViewController?) {
        
        IAPHandler.shared.purchaseStatusBlock = { type in
            let model: AlertViewModel
            switch type {
            case .purchased:
                model = AlertViewModel(localizedTitle: .donate_thankYouTitle, message: .donate_thankYouMessage, actions: [.dismiss], style: .alert)
            case .failed(let error):
                model = AlertViewModel(title: LocalizedStringKey.message_errorOccurred.localized, message: "Couldn't complete purchase, error: " + error.localizedDescription, actions: [.dismiss], style: .alert)
            }
            let alert = AWAlertController(model: model)
            DispatchQueue.main.async {
                controller?.present(alert, animated: true, completion: nil)
            }
            IAPHandler.shared.purchaseStatusBlock = nil
        }
        
        IAPHandler.shared.fetchAvailableProducts { products in
            var actions = [UIAlertAction.cancel()]
            let filtered = products.filter({ $0.productIdentifier.contains("tip") })
            let sorted = filtered.sorted { pro1, pro2 in
                return Int(pro1.productIdentifier.replacingOccurrences(of: ",", with: ".")) ?? 0 < Int(pro2.productIdentifier.replacingOccurrences(of: ",", with: ".")) ?? 0
            }
            for product in sorted {
                var title: String
                switch product.productIdentifier {
                case IAPHandler.SMALL_TIP_PRODUCT_ID:
                    title = "\(LocalizedStringKey.donate_small.localized): "
                case IAPHandler.BIG_TIP_PRODUCT_ID:
                    title = "\(LocalizedStringKey.donate_big.localized): "
                case IAPHandler.MEDIUM_TIP_PRODUCT_ID:
                    title = "\(LocalizedStringKey.donate_medium.localized): "
                default:
                    return
                }
                title += product.priceString ?? ""
                actions.append(UIAlertAction(title: title, style: .default, handler: { _ in
                    IAPHandler.shared.purchaseMyProduct(with: product.productIdentifier)
                }))
            }
            let model = AlertViewModel(title: LocalizedStringKey.donate_title.localized, message: LocalizedStringKey.donate_message.localized, actions: actions, style: .actionSheet)
            DispatchQueue.main.async {
                controller?.present(AWAlertController(model: model), animated: true, completion: nil)
            }
        }
    }
    
    class func presentUnlockController(in controller: UIViewController?, localizedTitle: LocalizedStringKey = .unlock_purchaseTitle, completion: ((Bool) -> Void)? = nil) {
        
        let unlockAction = UIAlertAction(localizedTitle: .unlock_purchaseAction, style: .default, handler: { _ in
            UnlockManager.unlock { error in
                let model: AlertViewModel
                if let error = error {
                    completion?(false)
                    model = AlertViewModel(title: LocalizedStringKey.message_errorOccurred.localized, message: "Couldn't complete purchase, error: " + error.localizedDescription, actions: [.dismiss], style: .alert)
                } else {
                    completion?(true)
                    model = AlertViewModel(localizedTitle: .unlock_thankYouTitle, message: .unlock_thankYouMessage, actions: [.dismiss], style: .alert)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    controller?.present(AWAlertController(model: model), animated: true, completion: nil)
                }
            }
        })
        
        let restoreAction = UIAlertAction(localizedTitle: .unlock_restoreAction, style: .default, handler: { _ in
            UnlockManager.restore { error in
                let model: AlertViewModel
                if let error = error {
                    completion?(false)
                    model = AlertViewModel(title: LocalizedStringKey.message_errorOccurred.localized, message: "Couldn't restore purchase, error: " + error.localizedDescription, actions: [.dismiss], style: .alert)
                } else {
                    completion?(true)
                    model = AlertViewModel(localizedTitle: .unlock_thankYouTitle, message: .unlock_thankYouMessage, actions: [.dismiss], style: .alert)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    controller?.present(AWAlertController(model: model), animated: true, completion: nil)
                }
            }
        })
        
        IAPHandler.shared.fetchAvailableProducts { products in
            guard products.contains(where: { $0.productIdentifier == IAPHandler.FULL_VERSION_PRODUCT_ID }) else {
                completion?(false)
                return
            }
            
            let actions: [UIAlertAction] = [
               unlockAction, restoreAction,
                UIAlertAction(title: LocalizedStringKey.cancel.localized, style: .cancel, handler: { _ in
                    completion?(false)
                })
            ]
            
            let model = AlertViewModel(localizedTitle: localizedTitle, message: .unlock_purchaseMessage, actions: actions, style: .alert)
            
            DispatchQueue.main.async {
                controller?.present(AWAlertController(model: model), animated: true, completion: nil)
            }
        }
    }
}
