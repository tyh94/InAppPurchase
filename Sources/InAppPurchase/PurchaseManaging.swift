//
//  PurchaseManaging.swift
//  InAppPurchase
//
//  Created by Татьяна Макеева on 21.08.2025.
//

import Combine
import Foundation
import StoreKit

public protocol PurchaseManaging: Sendable {
    var products: [Product] { get }
    var purchasedIDs: Set<String> { get }
    var purchasedIDsPublisher: AnyPublisher<Set<String>, Never> { get }
    
    func fetchProducts() async
    func purchase(_ product: Product) async
    func restorePurchases() async
    func updatePurchasedProducts() async
}
