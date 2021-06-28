//
//  AWAlertViewController.swift
//  Glarm
//
//  Created by Adam Wienconek on 22/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import UIKit
import AWAlertController

extension AWAlertController {
    class func showAlert(with title: String?, message: String?, dismissTitle: String = "Dismiss") {
        let model = AlertViewModel(title: title, message: message, actions: [
            UIAlertAction(title: dismissTitle, style: .cancel, handler: nil)
        ], style: .alert)
        AWAlertController(model: model).show()
    }
}
