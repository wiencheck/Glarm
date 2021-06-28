//
//  AlertViewModel.swift
//  Glarm
//
//  Created by Adam Wienconek on 22/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import UIKit
import AWAlertController

struct AlertViewModel {
    let title: String?
    let message: String?
    let actions: [UIAlertAction]
    let style: UIAlertController.Style
        
    init(title: String?, message: String?, actions: [UIAlertAction], style: UIAlertController.Style) {
        self.title = title
        self.message = message
        self.actions = actions
        self.style = style
    }
    
    init(localizedTitle: LocalizedStringKey?, message: LocalizedStringKey?, actions: [UIAlertAction], style: UIAlertController.Style) {
        self.init(title: localizedTitle?.localized, message: message?.localized, actions: actions, style: style)
    }
}

extension AWAlertController {
    convenience init(model: AlertViewModel) {
        self.init(title: model.title, message: model.message, preferredStyle: model.style)
        model.actions.forEach({ self.addAction($0) })
    }
}
