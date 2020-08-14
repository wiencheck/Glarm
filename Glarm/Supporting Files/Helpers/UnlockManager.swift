//
//  UnlockManager.swift
//  Glarm
//
//  Created by Adam Wienconek on 13/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit

final class UnlockManager {
    class var unlocked: Bool {
        guard Config.appConfiguration == .release else {
            return true
        }
        return IAPHandler.shared.didPurchaseFullVersion
    }
    
    class func unlock(completion: ((Error?) -> Void)?) {
        IAPHandler.shared.purchaseStatusBlock = { status in
            switch status {
            case .purchased:
                completion?(nil)
            case .failed(let error):
                completion?(error)
            }
            IAPHandler.shared.purchaseStatusBlock = nil
        }
        IAPHandler.shared.purchaseMyProduct(with: IAPHandler.FULL_VERSION_PRODUCT_ID)
    }
    
    class func restore(completion: ((Error?) -> Void)?) {
        IAPHandler.shared.purchaseStatusBlock = { status in
            switch status {
            case .purchased:
                completion?(nil)
            case .failed(let error):
                completion?(error)
            }
            IAPHandler.shared.purchaseStatusBlock = nil
        }
        IAPHandler.shared.restorePurchase()
    }
}
