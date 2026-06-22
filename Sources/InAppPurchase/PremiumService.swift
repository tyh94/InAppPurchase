//
//  PremiumService.swift
//  FamilyBook
//
//  Created by Татьяна Макеева on 15.08.2025.
//

import Combine
import Foundation
import Observation
import StoreKit

@MainActor
@Observable
public final class PremiumService {
    private let purchaseManager: PurchaseManaging
    private let storage: KeyValueStorage
    private let storageKey: String
    private let logger: Logger?

    private var expirationTask: Task<Void, Never>?

    public private(set) var isPremium: Bool = false
    public private(set) var premiumStatus: PremiumStatus = .init()
    public private(set) var products: [Product] = []
    public private(set) var isLoading: Bool = false
    public private(set) var purchaseError: Error? = nil

    public convenience init(
        productIDs: [String],
        storage: KeyValueStorage,
        storageKey: String = "premiumStatus",
        logger: Logger? = nil
    ) {
        self.init(
            purchaseManager: PurchaseManager(
                productIDs: productIDs,
                logger: logger
            ),
            storage: storage,
            storageKey: storageKey,
            logger: logger
        )
    }

    public init(
        purchaseManager: PurchaseManaging,
        storage: KeyValueStorage,
        storageKey: String,
        logger: Logger?
    ) {
        self.purchaseManager = purchaseManager
        self.storage = storage
        self.storageKey = storageKey
        self.logger = logger

        premiumStatus = (try? storage.object(forKey: storageKey)) ?? .init()
        isPremium = premiumStatus.isPremium
    }

    public func start() async {
        isLoading = true
        purchaseError = nil
        await purchaseManager.fetchProducts()
        products = purchaseManager.products
        await purchaseManager.updatePurchasedProducts()
        await updatePremiumStatus()
        isLoading = false
    }

    public func purchase(_ product: Product) async {
        isLoading = true
        purchaseError = nil
        await purchaseManager.purchase(product)
        await updatePremiumStatus()
        isLoading = false
    }

    public func restorePurchases() async {
        isLoading = true
        purchaseError = nil
        await purchaseManager.restorePurchases()
        products = purchaseManager.products
        await updatePremiumStatus()
        isLoading = false
    }

    #if DEBUG
    public func debugReset() {
        try? storage.removeObject(forKey: storageKey)
        let empty = PremiumStatus()
        premiumStatus = empty
        isPremium = false
        expirationTask?.cancel()
        expirationTask = nil
        logger?.debug("🔧 PremiumService debugReset(): статус сброшен")
    }
    #endif

    private func updatePremiumStatus() async {
        var status = PremiumStatus()

        for product in purchaseManager.products {
            if purchaseManager.purchasedIDs.contains(product.id) {
                switch product.type {
                case .nonConsumable:
                    status = PremiumStatus(isLifetime: true)
                case .autoRenewable:
                    if let t = await Transaction.latest(for: product.id),
                       case .verified(let transaction) = t,
                       let expiration = transaction.expirationDate {
                        status = PremiumStatus(isLifetime: false, expirationDate: expiration)
                    }
                default:
                    break
                }
            }
        }

        try? storage.set(status, forKey: storageKey)
        premiumStatus = status
        isPremium = status.isPremium
        scheduleExpirationCheck(for: status)
    }

    private func scheduleExpirationCheck(for status: PremiumStatus) {
        expirationTask?.cancel()
        guard let expirationDate = status.expirationDate else { return }
        let interval = expirationDate.timeIntervalSinceNow
        guard interval > 1 else { return }

        expirationTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(for: .seconds(interval))
            } catch {
                return
            }
            await self.updatePremiumStatus()
        }
    }
}

extension PremiumService {
    public static func preview(isPremium: Bool = false) -> PremiumService {
        let storage = KeyValueStorageMock(objects: isPremium
            ? ["premiumStatus": (try? JSONEncoder().encode(PremiumStatus(isLifetime: true))) ?? Data()]
            : [:]
        )
        return PremiumService(
            purchaseManager: PurchaseManagerMock(simulatePurchased: isPremium),
            storage: storage,
            storageKey: "premiumStatus",
            logger: nil
        )
    }
}
