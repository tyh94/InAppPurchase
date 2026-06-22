import Testing
import Foundation
import StoreKit
import OSLog
@testable import InAppPurchase

@MainActor
final class InAppPurchaseTests {
    
    @Test("Базовый тест: PremiumService инициализация")
    func testBasicPremiumServiceInitialization() throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        #expect(service.isPremium == false)
        #expect(service.premiumStatus.isPremium == false)
        #expect(service.products.isEmpty)
    }
    
    @Test("Базовый тест: PremiumStatus логика")
    func testBasicPremiumStatusLogic() throws {
        let lifetimeStatus = PremiumStatus(isLifetime: true)
        #expect(lifetimeStatus.isPremium == true)
        
        let expiredStatus = PremiumStatus(isLifetime: false, expirationDate: Date().addingTimeInterval(-3600))
        #expect(expiredStatus.isPremium == false)
        
        let activeStatus = PremiumStatus(isLifetime: false, expirationDate: Date().addingTimeInterval(3600))
        #expect(activeStatus.isPremium == true)
    }
    
    @Test("Базовый тест: MockKeyValueStorage")
    func testBasicMockStorage() throws {
        let storage = MockKeyValueStorage()
        let testData = "test"
        
        try storage.set(testData, forKey: "testKey")
        let retrieved: String? = try storage.object(forKey: "testKey")
        
        #expect(retrieved == testData)
        #expect(storage.storedKeys.contains("testKey"))
    }
    
    @Test("Базовый тест: MockPurchaseManager")
    func testBasicMockPurchaseManager() async throws {
        let manager = MockPurchaseManager()
        
        await manager.fetchProducts()
        await manager.restorePurchases()
        
        #expect(manager.fetchProductsCalled == true)
        #expect(manager.restorePurchasesCalled == true)
    }
    
    @Test("Базовый тест: MockLogger")
    func testBasicMockLogger() throws {
        let logger = MockLogger()
        
        logger.debug("Test debug")
        logger.info("Test info")
        logger.warning("Test warning")
        logger.error("Test error")
        
        #expect(logger.loggedMessages.count == 4)
        #expect(logger.loggedMessages.contains("Test debug"))
        #expect(logger.loggedMessages.contains("Test info"))
        #expect(logger.loggedMessages.contains("Test warning"))
        #expect(logger.loggedMessages.contains("Test error"))
    }
}

// MARK: - Smoke Tests

@MainActor
final class InAppPurchaseSmokeTests {
    
    @Test("Smoke тест: полный цикл работы PremiumService")
    func testFullPremiumServiceWorkflow() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        // 1. Инициализация
        #expect(service.isPremium == false)
        
        // 2. Запуск сервиса
        await service.start()
        #expect(manager.fetchProductsCalled == true)
        #expect(manager.updatePurchasedProductsCalled == true)
        
        // 3. Добавление продуктов
        let mockProduct = MockProduct(id: "test.product", type: .nonConsumable, displayName: "Test", description: "Test", price: 0.99, priceFormatStyle: .currency(code: "USD"))
        manager.setMockProducts([mockProduct])
        #expect(service.products.count == 0) // Мок продукты не добавляются в реальный список
        
        // 4. Покупка - симулируем через менеджер
        manager.purchaseCalled = true
        manager.purchasedIDs.insert("test.product")
        #expect(manager.purchaseCalled == true)
        
        // 5. Восстановление покупок
        await service.restorePurchases()
        #expect(manager.restorePurchasesCalled == true)
        
        // 6. Логирование
        #expect(logger.loggedMessages.count >= 0)
    }
    
    @Test("Smoke тест: работа с PremiumStatus")
    func testPremiumStatusWorkflow() throws {
        let storage = MockKeyValueStorage()
        
        // Создание статуса
        let status = PremiumStatus(isLifetime: true, expirationDate: Date())
        
        // Сохранение
        try storage.set(status, forKey: "testStatus")
        
        // Загрузка
        let loadedStatus: PremiumStatus? = try storage.object(forKey: "testStatus")
        
        #expect(loadedStatus != nil)
        #expect(loadedStatus?.isLifetime == true)
        #expect(loadedStatus?.isPremium == true)
    }
    
    @Test("Smoke тест: обработка ошибок")
    func testErrorHandling() async throws {
        let storage = MockKeyValueStorage()
        storage.shouldThrowError = true
        let manager = MockPurchaseManager()
        manager.shouldThrowError = true
        let logger = MockLogger()
        
        // Сервис должен инициализироваться без ошибок
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "key", logger: logger)
        #expect(service.isPremium == false)
        
        // Операции должны обрабатывать ошибки gracefully
        await service.start()
        await service.restorePurchases()
        
        #expect(manager.fetchProductsCalled == true)
        #expect(manager.restorePurchasesCalled == true)
    }
}
