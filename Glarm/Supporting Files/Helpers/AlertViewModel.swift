//
//  AlertViewModel.swift
//  Glarm
//
//  Created by Adam Wienconek on 13/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit

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
        self.title = localizedTitle?.localized
        self.message = message?.localized
        self.actions = actions
        self.style = style
    }
}
