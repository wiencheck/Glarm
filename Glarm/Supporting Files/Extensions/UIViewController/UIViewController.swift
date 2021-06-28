//
//  UIViewController.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 06/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import AWAlertController

extension UIViewController {
    func displayErrorMessage(title: String?, error: Error?) {
        let alert = AWAlertController(title: title ?? LocalizedStringKey.message_errorOccurred.localized, message: error?.localizedDescription ?? LocalizedStringKey.message_errorUnknown.localized, preferredStyle: .alert)
        alert.addAction(.cancel(text: LocalizedStringKey.dismiss.localized))
        present(alert, animated: true, completion: nil)
    }
}
