//
//  LanguageKey.swift
//  Plum 2
//
//  Created by Adam Wienconek on 03.06.2018.
//  Copyright © 2018 Adam Wienconek. All rights reserved.
//

import Foundation

enum LanguageTableKey: String {
    case english = "en"
    case polish = "pl"
//    case german = "German"
//    case italian = "Italian"
//    case spanish = "Spanish"
//    case portuguese = "Portuguese"
//    case russian = "Russian"
//    case french = "French"
    
    init?(locale: Locale) {
        let code = locale.languageCode ?? "en"
        self.init(rawValue: code)
    }
}
