//
//  PremiumService.swift
//  FamilyBook
//
//  Created by Татьяна Макеева on 15.08.2025.
//

import Combine
import Foundation
import StoreKit

@MainActor
public final class PremiumService: ObservableObject {
    private let purchaseManager: PurchaseManaging
    private let storage: KeyValueStorage
    private let storageKey: String
    private let logger: Logger?
    
    private var expirationTask: Task<Void, Never>?
    
    @Published public private(set) var isPremium: Bool = false
    @Published public private(set) var premiumStatus: PremiumStatus = .init()
    
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
    
    deinit {
        expirationTask?.cancel()
    }
    
    public func start() async {
        await purchaseManager.fetchProducts()
        await purchaseManager.updatePurchasedProducts()
        await updatePremiumStatus()
    }
    
    public func purchase(_ product: Product) async {
        await purchaseManager.purchase(product)
        await updatePremiumStatus()
    }
    
    public func restorePurchases() async {
        await purchaseManager.restorePurchases()
        await updatePremiumStatus()
    }
    
    public var products: [Product] {
        purchaseManager.products
    }
    
    #if DEBUG
    public func debugReset() {
        // 1. Чистим локальное хранилище
        try? storage.removeObject(forKey: storageKey)
        
        // 2. Сбрасываем PremiumStatus
        let empty = PremiumStatus()
        premiumStatus = empty
        isPremium = false
        
        // 3. Останавливаем задачу истечения
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
                    // Достаём датy истечения транзакции
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

        await MainActor.run {
            premiumStatus = status
            isPremium = status.isPremium
            scheduleExpirationCheck(for: status)
        }
    }
    
    private func scheduleExpirationCheck(for status: PremiumStatus) {
        expirationTask?.cancel()
        
        guard let expirationDate = status.expirationDate else {
            return
        }
        
        // пересчитываем интервал заново
        let interval = expirationDate.timeIntervalSinceNow
        
        // если дата странная / отрицательная — не считаем что подписка истекла
        guard interval > 1 else {
            // StoreKit сам пришлёт событие об истечении
            return
        }
        
        expirationTask = Task { [weak self] in
            guard let self else { return }
            
            do {
                try await Task.sleep(for: .seconds(interval))
            } catch {
                return // cancelled
            }
            
            // после таймера — проверяем ещё раз через StoreKit, а не сами сбрасываем
            await self.updatePremiumStatus()
        }
    }
}
