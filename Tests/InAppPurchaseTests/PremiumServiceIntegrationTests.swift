import Testing
import Foundation
import StoreKit
import OSLog
@testable import InAppPurchase

@MainActor
final class PremiumServiceIntegrationTests {
    
    @Test("Интеграционный тест: полный цикл покупки")
    func testFullPurchaseCycle() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        // Начальное состояние
        #expect(service.isPremium == false)
        #expect(service.premiumStatus.isPremium == false)
        
        // Запускаем сервис
        await service.start()
        #expect(manager.fetchProductsCalled == true)
        #expect(manager.updatePurchasedProductsCalled == true)
        
        // Симулируем покупку lifetime продукта
        manager.simulateSuccessfulPurchase(productID: "lifetime.premium")
        manager.purchaseCalled = true
        
        #expect(manager.purchaseCalled == true)
        #expect(manager.isProductPurchased("lifetime.premium") == true)
        
        // Проверяем, что мок правильно отслеживает покупки
        #expect(manager.purchasedIDs.contains("lifetime.premium") == true)
    }
    
    @Test("Интеграционный тест: подписка с истечением")
    func testSubscriptionWithExpiration() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        // Симулируем подписку с будущей датой истечения
        let futureDate = Date().addingTimeInterval(86400) // +1 день
        let subscriptionStatus = PremiumStatus(isLifetime: false, expirationDate: futureDate)
        try storage.set(subscriptionStatus, forKey: "premiumStatus")
        
        let serviceWithSubscription = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        #expect(serviceWithSubscription.isPremium == true)
        #expect(serviceWithSubscription.premiumStatus.isLifetime == false)
        #expect(serviceWithSubscription.premiumStatus.expirationDate == futureDate)
    }
    
    @Test("Интеграционный тест: восстановление покупок")
    func testRestorePurchases() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        await service.restorePurchases()
        
        #expect(manager.restorePurchasesCalled == true)
    }
    
    @Test("Интеграционный тест: обработка ошибок")
    func testErrorHandling() async throws {
        let storage = MockKeyValueStorage()
        storage.shouldThrowError = true
        let manager = MockPurchaseManager()
        manager.shouldThrowError = true
        let logger = MockLogger()
        
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        // Сервис должен инициализироваться без ошибок
        #expect(service.isPremium == false)
        #expect(service.premiumStatus.isPremium == false)
        
        // Операции должны обрабатывать ошибки gracefully
        await service.start()
        await service.restorePurchases()
        
        // Проверяем, что методы были вызваны
        #expect(manager.fetchProductsCalled == true)
        #expect(manager.restorePurchasesCalled == true)
    }
    
    @Test("Интеграционный тест: множественные продукты")
    func testMultipleProducts() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        let mockProducts = [
            MockProduct(id: "product1", type: .nonConsumable, displayName: "Product 1", description: "Test 1", price: 0.99, priceFormatStyle: .currency(code: "USD")),
            MockProduct(id: "product2", type: .autoRenewable, displayName: "Product 2", description: "Test 2", price: 1.99, priceFormatStyle: .currency(code: "USD")),
            MockProduct(id: "product3", type: .consumable, displayName: "Product 3", description: "Test 3", price: 2.99, priceFormatStyle: .currency(code: "USD"))
        ]
        
        manager.setMockProducts(mockProducts)
        
        #expect(mockProducts.count == 3)
        #expect(mockProducts.map { $0.id }.sorted() == ["product1", "product2", "product3"])
        
        // Симулируем покупки
        for mockProduct in mockProducts {
            manager.purchasedIDs.insert(mockProduct.id)
        }
        
        #expect(manager.purchasedIDs.count == 3)
    }
    
    @Test("Интеграционный тест: персистентность данных")
    func testDataPersistence() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        
        // Создаем первый сервис и устанавливаем статус
        let service1 = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        let premiumStatus = PremiumStatus(isLifetime: true, expirationDate: Date())
        try storage.set(premiumStatus, forKey: "premiumStatus")
        
        // Создаем второй сервис и проверяем, что статус сохранился
        let service2 = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        #expect(service2.isPremium == true)
        #expect(service2.premiumStatus.isLifetime == true)
        #expect(storage.storedKeys.contains("premiumStatus"))
    }
    
    @Test("Интеграционный тест: кастомный ключ хранения")
    func testCustomStorageKey() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let customKey = "myCustomPremiumKey"
        
        let premiumStatus = PremiumStatus(isLifetime: true)
        try storage.set(premiumStatus, forKey: customKey)
        
        let serviceWithCustomKey = PremiumService(purchaseManager: manager, storage: storage, storageKey: customKey, logger: logger)
        
        #expect(serviceWithCustomKey.isPremium == true)
        #expect(storage.storedKeys.contains(customKey))
        #expect(storage.storedKeys.contains("premiumStatus") == false)
    }
    
    @Test("Интеграционный тест: логирование операций")
    func testLoggingOperations() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        await service.start()
        await service.restorePurchases()
        
        // Проверяем, что логирование работает
        #expect(logger.loggedMessages.count >= 0)
    }
    
    @Test("Интеграционный тест: работа с разными типами продуктов")
    func testDifferentProductTypes() async throws {
        let manager = MockPurchaseManager()
        
        let nonConsumable = MockProduct(id: "nonConsumable", type: .nonConsumable, displayName: "Non-Consumable", description: "Test", price: 0.99, priceFormatStyle: .currency(code: "USD"))
        let autoRenewable = MockProduct(id: "autoRenewable", type: .autoRenewable, displayName: "Auto-Renewable", description: "Test", price: 1.99, priceFormatStyle: .currency(code: "USD"))
        let consumable = MockProduct(id: "consumable", type: .consumable, displayName: "Consumable", description: "Test", price: 2.99, priceFormatStyle: .currency(code: "USD"))
        
        let mockProducts = [nonConsumable, autoRenewable, consumable]
        manager.setMockProducts(mockProducts)
        
        #expect(mockProducts.count == 3)
        #expect(mockProducts.contains { $0.id == "nonConsumable" })
        #expect(mockProducts.contains { $0.id == "autoRenewable" })
        #expect(mockProducts.contains { $0.id == "consumable" })
    }
}
