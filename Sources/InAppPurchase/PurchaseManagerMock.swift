//
//  PurchaseManagerMock.swift
//  InAppPurchase
//
//  Created by Татьяна Макеева on 22.06.2026.
//

import Combine
import Foundation
import StoreKit

public final class PurchaseManagerMock: PurchaseManaging, @unchecked Sendable {
    public var products: [Product] = []

    @Published public private(set) var purchasedIDs: Set<String>

    public var purchasedIDsPublisher: AnyPublisher<Set<String>, Never> {
        $purchasedIDs.eraseToAnyPublisher()
    }

    public init(simulatePurchased: Bool = false, productID: String = "preview.product") {
        self.purchasedIDs = simulatePurchased ? [productID] : []
    }

    public func fetchProducts() async {}
    public func purchase(_ product: Product) async { purchasedIDs.insert(product.id) }
    public func restorePurchases() async {}
    public func updatePurchasedProducts() async {}
}

