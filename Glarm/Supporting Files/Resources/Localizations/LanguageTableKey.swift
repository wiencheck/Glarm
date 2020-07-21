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
//    case german = "de"
//    case italian = "Italian"
//    case spanish = "Spanish"
//    case portuguese = "Portuguese"
//    case russian = "Russian"
//    case french = "French"
    
    static var preferred: LanguageTableKey {
        let locale = Locale.preferred
        let code = locale.languageCode ?? "en"
        return LanguageTableKey(rawValue: code) ?? .english
    }
}
