//
//  SKProduct.swift
//  Plum
//
//  Created by adam.wienconek on 04.12.2018.
//  Copyright © 2018 adam.wienconek. All rights reserved.
//

import StoreKit

extension SKProduct {
    var priceString: String? {
        if price == NSDecimalNumber(decimal: 0.00) {
            return "Free"
        } else {
            let numberFormatter = NumberFormatter()
            let locale = priceLocale
            numberFormatter.numberStyle = .currency
            numberFormatter.locale = locale
            return numberFormatter.string(from: price)
        }
    }
}
