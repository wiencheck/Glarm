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
    
    func message() -> String{
        switch self {
        case .purchased: return "You've successfully bought this purchase!"
        case .failed(let error):
            return error.localizedDescription
        }
    }
}

final class IAPHandler: NSObject {
    static let shared = IAPHandler()
    
    static let fullVersionPurchasedNotification = Notification.Name("fullVersionPurchasedNotification")
    
    static let TINY_TIP_PRODUCT_ID = "tiny.tip"
    static let SMALL_TIP_PRODUCT_ID = "small.tip"
    static let MEDIUM_TIP_PRODUCT_ID = "medium.tip"
    static let BIG_TIP_PRODUCT_ID = "big.tip"
    static let ENOURMOUS_TIP_PRODUCT_ID = "enourmous.tip"
    static let FULL_VERSION_PRODUCT_ID = "full.version.unlock"
    static let purchasedProductsKey = "purchasedProducts"
    
    fileprivate var productID = ""
    fileprivate var productsRequest = SKProductsRequest()
    public var iapProducts = [SKProduct]()
    
    public class var purchasedProductsIdentifiers: Set<String> {
        get {
            let arr = UserDefaults.standard.stringArray(forKey: IAPHandler.purchasedProductsKey) ?? []
            return Set(arr)
        } set {
            if purchasedProductsIdentifiers == newValue { return }
            print("Purchased products: ", newValue)
            let arr = [String](newValue)
            UserDefaults.standard.set(arr, forKey: IAPHandler.purchasedProductsKey)
            NotificationCenter.default.post(name: IAPHandler.fullVersionPurchasedNotification, object: didPurchaseFullVersion)

        }
    }
    
    public class var didPurchaseFullVersion: Bool {
        return purchasedProductsIdentifiers.contains(IAPHandler.FULL_VERSION_PRODUCT_ID)
    }
    
    private var currentProduct: SKProduct?
    
    var purchaseStatusBlock: ((IAPHandlerAlertType) -> Void)?
    private var onProductsFetch: (([SKProduct]) -> Void)?
    
    // MARK: - MAKE PURCHASE OF A PRODUCT
    func canMakePurchases() -> Bool {  return SKPaymentQueue.canMakePayments()  }
    
    private override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    func purchaseMyProduct(index: Int) {
        if iapProducts.isEmpty { return }
        
        guard canMakePurchases() else {
            let error = AWError(description: "Purchases are disabled for this device")
            purchaseStatusBlock?(.failed(error))
            return
        }
        let product = iapProducts[index]
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        
        print("PRODUCT TO PURCHASE: \(product.productIdentifier)")
        productID = product.productIdentifier
    }
    
    func purchaseMyProduct(with identifier: String) {
        if iapProducts.count == 0 { return }
        
        guard canMakePurchases() else {
            let error = AWError(description: "Purchases are disabled for this device")
            purchaseStatusBlock?(.failed(error))
            return
        }
        guard let product = iapProducts.first(where: { $0.productIdentifier == identifier }) else { return }
        currentProduct = product
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
        let productIdentifiers = NSSet(objects: IAPHandler.SMALL_TIP_PRODUCT_ID,IAPHandler.TINY_TIP_PRODUCT_ID, IAPHandler.MEDIUM_TIP_PRODUCT_ID, IAPHandler.BIG_TIP_PRODUCT_ID, IAPHandler.ENOURMOUS_TIP_PRODUCT_ID, IAPHandler.FULL_VERSION_PRODUCT_ID)
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers as! Set<String>)
        productsRequest.delegate = self
        productsRequest.start()
    }
}

extension IAPHandler: SKProductsRequestDelegate, SKPaymentTransactionObserver {
    // MARK: - REQUEST IAP PRODUCTS
    func productsRequest (_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        iapProducts = response.products
        onProductsFetch?(response.products)
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        if queue.transactions.isEmpty {
            let error = AWError(description: "No purchases were available to restore")
            purchaseStatusBlock?(.failed(error))
            return
        }
        for transcation in queue.transactions {
            let identifier = transcation.payment.productIdentifier
            IAPHandler.purchasedProductsIdentifiers.insert(identifier)
        }
        if IAPHandler.didPurchaseFullVersion {
            NotificationCenter.default.post(name: IAPHandler.fullVersionPurchasedNotification, object: IAPHandler.shared)
        }
        purchaseStatusBlock?(.purchased)
    }
    
    // MARK:- IAP PAYMENT QUEUE
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
            IAPHandler.purchasedProductsIdentifiers.insert(transaction.payment.productIdentifier)
                purchaseStatusBlock?(.purchased)
            case .failed:
                let error = AWError(description: "Purchase failed")
                purchaseStatusBlock?(.failed(error))
            default: break
            }
            if transaction.transactionState == .purchasing { continue }
            SKPaymentQueue.default().finishTransaction(transaction)
        }
    }
}
