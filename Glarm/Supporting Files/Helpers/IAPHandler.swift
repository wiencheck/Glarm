//
//  IAPHandler.swift
//  Glarm
//
//  Created by Adam Wienconek on 13/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import StoreKit

enum IAPHandlerAlertType {
    case purchased
    case failed(Error)
    
    func message() -> String {
        switch self {
        case .purchased: return "You've successfully purchased protduct!"
        case .failed(let error):
            return error.localizedDescription
        }
    }
}

final class IAPHandler: NSObject {
    static let shared = IAPHandler()
    
    static let SMALL_TIP_PRODUCT_ID = "glarm.small.tip"
    static let MEDIUM_TIP_PRODUCT_ID = "glarm.medium.tip"
    static let BIG_TIP_PRODUCT_ID = "glarm.big.tip"
    static let FULL_VERSION_PRODUCT_ID = "glarm.full.version.unlock"
    static let purchasedProductsKey = "glarm.purchasedProducts"
    
    class var consumableProductIdentifiers: [String] {
        return [SMALL_TIP_PRODUCT_ID, MEDIUM_TIP_PRODUCT_ID, BIG_TIP_PRODUCT_ID]
    }
    
    fileprivate var productID = ""
    fileprivate var productsRequest = SKProductsRequest()
    public var iapProducts = [SKProduct]()
    
    public static let purchasedProductIdentifiersChangedNotification = Notification.Name("purchasedProductIdentifiersChangedNotification")
    public static let PurchasedProductIdentifiersKey = "PurchasedProductIdentifiersKey"
    
    public var purchasedProductsIdentifiers: Set<String> {
        get {
            let arr = UserDefaults.standard.stringArray(forKey: IAPHandler.purchasedProductsKey) ?? []
            return Set(arr)
        } set {
            if purchasedProductsIdentifiers == newValue { return }
            print("Purchased products: ", newValue)
            let arr = [String](newValue)
            UserDefaults.standard.set(arr, forKey: IAPHandler.purchasedProductsKey)
            NotificationCenter.default.post(name: IAPHandler.purchasedProductIdentifiersChangedNotification, object: self, userInfo: [IAPHandler.PurchasedProductIdentifiersKey: purchasedProductsIdentifiers])
        }
    }
    
    public var didPurchaseFullVersion: Bool {
        return true
        // return purchasedProductsIdentifiers.contains(IAPHandler.FULL_VERSION_PRODUCT_ID)
    }
    
    //private var currentProduct: SKProduct?
    
    var purchaseStatusBlock: ((IAPHandlerAlertType) -> Void)?
    private var onProductsFetch: (([SKProduct]) -> Void)?
    
    // MARK: - MAKE PURCHASE OF A PRODUCT
    func canMakePurchases() -> Bool {  return SKPaymentQueue.canMakePayments()  }
    
    private override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    func purchaseMyProduct(index: Int) {
        guard canMakePurchases() else {
            let error = AWError(description: "Purchases are disabled for this device")
            purchaseStatusBlock?(.failed(error))
            return
        }
        guard let product = iapProducts.at(index) else {
            return
        }
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        
        print("PRODUCT TO PURCHASE: \(product.productIdentifier)")
        productID = product.productIdentifier
    }
    
    func purchaseMyProduct(with identifier: String) {
        guard canMakePurchases() else {
            let error = AWError(description: "Purchases are disabled for this device")
            purchaseStatusBlock?(.failed(error))
            return
        }
        guard let product = iapProducts.first(where: { $0.productIdentifier == identifier }) else {
            return
        }
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        
        print("PRODUCT TO PURCHASE: \(product.productIdentifier)")
        productID = product.productIdentifier
    }
    
    // MARK: - RESTORE PURCHASE
    func restorePurchase() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // MARK: - FETCH AVAILABLE IAP PRODUCTS
    func fetchAvailableProducts(completion: (([SKProduct]) -> Void)?) {
        
        onProductsFetch = completion
        // Put here your IAP Products ID's
        let productIdentifiers = Set([ IAPHandler.SMALL_TIP_PRODUCT_ID, IAPHandler.BIG_TIP_PRODUCT_ID, IAPHandler.MEDIUM_TIP_PRODUCT_ID,
            IAPHandler.FULL_VERSION_PRODUCT_ID])
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest.delegate = self
        productsRequest.start()
    }
}

extension IAPHandler: SKProductsRequestDelegate, SKPaymentTransactionObserver {
    // MARK: - REQUEST IAP PRODUCTS
    internal func productsRequest (_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        iapProducts = response.products
        onProductsFetch?(response.products)
    }
    
    internal func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        if queue.transactions.isEmpty {
            let error = AWError(description: "No purchases were available to restore")
            purchaseStatusBlock?(.failed(error))
            return
        }
        handleTransactions(queue.transactions, queue: queue)
    }
    
    // MARK:- IAP PAYMENT QUEUE
    internal func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        handleTransactions(transactions, queue: queue)
    }
    
    private func handleTransactions(_ transactions: [SKPaymentTransaction], queue: SKPaymentQueue) {
        
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing, .deferred:
                continue // do nothing
            case .purchased, .restored:
                let identifier = transaction.payment.productIdentifier
                // Don't add consumable products.
                if !IAPHandler.consumableProductIdentifiers.contains(identifier) {
                    purchasedProductsIdentifiers.insert(identifier)
                }
                purchaseStatusBlock?(.purchased)
            case .failed:
                let error = AWError(description: "Purchase failed")
                purchaseStatusBlock?(.failed(error))
            default:
                break
            }
            queue.finishTransaction(transaction)
        }
    }
}
