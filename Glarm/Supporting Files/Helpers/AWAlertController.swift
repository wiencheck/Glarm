//
//  AWAlertController.swift
//  Glarm
//
//  Created by Adam Wienconek on 13/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit

class AWAlertController: UIAlertController {
    
    var onTextFieldChange: ((UITextField) -> Void)?
    
    convenience init(model: AlertViewModel) {
        self.init(title: model.title, message: model.message, preferredStyle: model.style)
        model.actions.forEach({ self.addAction($0) })
    }
}

extension AWAlertController {
    override func addTextField(configurationHandler: ((UITextField) -> Void)? = nil) {
        super.addTextField(configurationHandler: configurationHandler)
        NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: nil, queue: nil) { [weak self] sender in
            guard let textField = sender.object as? UITextField else {
                return
            }
            self?.onTextFieldChange?(textField)
        }
    }
}

extension AWAlertController {
    class var notificationsPermissionRestrictedAlert: UIAlertController {
        let actions: [UIAlertAction] = [
            UIAlertAction(localizedTitle: .permission_openSettingsAction, style: .default, handler: { _ in
                UIApplication.shared.openSettings()
            }),
            .cancel()
        ]
        let model = AlertViewModel(localizedTitle: .permission_notificationDeniedTitle, message: .permission_notificationDeniedMessage, actions: actions, style: .alert)
        return AWAlertController(model: model)
    }
    
    class func presentDonationController() {
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
                UIApplication.shared.keyWindow()?.rootViewController?.present(alert, animated: true, completion: nil)
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
                case IAPHandler.ENOURMOUS_TIP_PRODUCT_ID:
                    title = "\(LocalizedStringKey.donate_enormous.localized): "
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
                UIApplication.shared.keyWindow()?.rootViewController?.present(AWAlertController(model: model), animated: true, completion: nil)
            }
        }
    }
}
