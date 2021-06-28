//
//  Alertable.swift
//  Glarm
//
//  Created by Adam Wienconek on 15/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import AWAlertController

protocol Alertable: UIViewController {
    func didReceiveAlert(model: AlertViewModel)
}

extension Alertable {
    func didReceiveAlert(model: AlertViewModel) {
        DispatchQueue.main.async {
            let alert = AWAlertController(model: model)
            self.present(alert, animated: true, completion: nil)
        }
    }
}
