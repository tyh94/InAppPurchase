//
//  PurchaseManager.swift
//  InAppPurchase
//
//  Created by Татьяна Макеева on 15.08.2025.
//

import Combine
import Foundation
import StoreKit

public final class PurchaseManager: PurchaseManaging, @unchecked Sendable {
    public private(set) var products: [Product] = []
    @Published public private(set) var purchasedIDs: Set<String> = []
    
    public var purchasedIDsPublisher: AnyPublisher<Set<String>, Never> {
        $purchasedIDs.eraseToAnyPublisher()
    }
    
    private let logger: Logger?
    private let productIDs: [String]
    private var updatesTask: Task<Void, Never>? = nil
    
    public init(
        productIDs: [String],
        logger: Logger?
    ) {
        self.productIDs = productIDs
        self.logger = logger
        self.setupTransactionUpdates()
    }
    
    deinit {
        updatesTask?.cancel()
    }
    
    /// Настройка отслеживания обновлений транзакций
    private func setupTransactionUpdates() {
        updatesTask = Task { [weak self] in
            guard let self else { return }
            
            for await update in Transaction.updates {
                await self.handle(transactionUpdate: update)
            }
        }
    }
    
    /// Обработка обновлений транзакций
    private func handle(transactionUpdate: VerificationResult<Transaction>) async {
        switch transactionUpdate {
        case .verified(let transaction):
            // Проверяем, была ли транзакция отозвана
            if transaction.revocationDate != nil {
                // Удаляем продукт из purchasedIDs
                purchasedIDs.remove(transaction.productID)
                logger?.debug("Транзакция отозвана: \(transaction.productID)")
            } else {
                // Обычная проверенная транзакция
                purchasedIDs.insert(transaction.productID)
            }
            await transaction.finish()
            
        case .unverified(let transaction, let error):
            logger?.error("Транзакция не проверена: \(error)")
            await transaction.finish()
        }
    }
    
    /// Загружает продукты из App Store
    public func fetchProducts() async {
        do {
            products = try await Product.products(for: productIDs)
            logger?.debug("Fetch products: \(products)")
        } catch {
            logger?.error("Ошибка загрузки продуктов: \(error)")
        }
    }
    
    /// Покупка продукта
    public func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(.verified(let transaction)):
                purchasedIDs.insert(transaction.productID)
                await transaction.finish()
            case .success(.unverified(_, let error)):
                logger?.debug("Покупка не подтверждена: \(error)")
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            logger?.error("Ошибка покупки: \(error)")
        }
    }
    
    /// Восстановление покупок
    public func restorePurchases() async {
        await updatePurchasedProducts()
    }
    
    /// Проверка покупок при старте приложения
    public func updatePurchasedProducts() async {
        var newPurchasedIDs = Set<String>()
        
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                // Проверяем, не отозвана ли транзакция
                if transaction.revocationDate == nil {
                    newPurchasedIDs.insert(transaction.productID)
                } else {
                    logger?.debug("Транзакция отозвана: \(transaction.productID)")
                }
            case .unverified(_, let error):
                logger?.error("Транзакция не проверена: \(error)")
            }
        }
        
        purchasedIDs = newPurchasedIDs
    }
}
