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
    
    private lazy var alertWindow: UIWindow = {
        let window = UIWindow()
        window.rootViewController = UIViewController()
        window.backgroundColor = .clear
        window.tintColor = .tint
        window.windowLevel = UIWindow.Level.alert
        return window
    }()
    
    public func show(animated flag: Bool = true, completion: (() -> Void)? = nil) {
        if let rootViewController = alertWindow.rootViewController {
            alertWindow.makeKeyAndVisible()
            if let popoverController = self.popoverPresentationController {
              popoverController.sourceView = alertWindow
              popoverController.sourceRect = CGRect(x: alertWindow.bounds.midX, y: alertWindow.bounds.midY, width: 0, height: 0)
              popoverController.permittedArrowDirections = []
            }
            rootViewController.present(self, animated: flag, completion: completion)
        }
    }
    
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
            UIAlertAction(localizedTitle: .openSettings, style: .default, handler: { _ in
                UIApplication.shared.openSettings()
            }),
            .cancel()
        ]
        let model = AlertViewModel(localizedTitle: .notificationPermissionDeniedTitle, message: .notificationPermissionDeniedMessage, actions: actions, style: .alert)
        return AWAlertController(model: model)
    }
}
