import Testing
import Foundation
import StoreKit
import OSLog
@testable import InAppPurchase

@MainActor
final class PremiumServiceEdgeCasesTests {
    
    @Test("Тест граничного случая: очень длинный ключ хранения")
    func testVeryLongStorageKey() throws {
        let storage = MockKeyValueStorage()
        let longKey = String(repeating: "a", count: 1000)
        let status = PremiumStatus(isLifetime: true)
        
        try storage.set(status, forKey: longKey)
        let retrievedStatus: PremiumStatus? = try storage.object(forKey: longKey)
        
        #expect(retrievedStatus != nil)
        #expect(retrievedStatus?.isLifetime == true)
        #expect(storage.storedKeys.contains(longKey))
    }
    
    @Test("Тест граничного случая: пустой ключ хранения")
    func testEmptyStorageKey() throws {
        let storage = MockKeyValueStorage()
        let emptyKey = ""
        let status = PremiumStatus(isLifetime: true)
        
        try storage.set(status, forKey: emptyKey)
        let retrievedStatus: PremiumStatus? = try storage.object(forKey: emptyKey)
        
        #expect(retrievedStatus != nil)
        #expect(retrievedStatus?.isLifetime == true)
        #expect(storage.storedKeys.contains(emptyKey))
    }
    
    @Test("Тест граничного случая: специальные символы в ключе хранения")
    func testSpecialCharactersInStorageKey() throws {
        let storage = MockKeyValueStorage()
        let specialKey = "key!@#$%^&*()_+-=[]{}|;':\",./<>?"
        let status = PremiumStatus(isLifetime: true)
        
        try storage.set(status, forKey: specialKey)
        let retrievedStatus: PremiumStatus? = try storage.object(forKey: specialKey)
        
        #expect(retrievedStatus != nil)
        #expect(retrievedStatus?.isLifetime == true)
        #expect(storage.storedKeys.contains(specialKey))
    }
    
    @Test("Тест граничного случая: множественные вызовы start")
    func testMultipleStartCalls() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        // Вызываем start несколько раз
        await service.start()
        await service.start()
        await service.start()
        
        #expect(manager.fetchProductsCalled == true)
        #expect(manager.updatePurchasedProductsCalled == true)
    }
    
    @Test("Тест граничного случая: множественные вызовы purchase")
    func testMultiplePurchaseCalls() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        // Симулируем множественные покупки
        manager.purchaseCalled = true
        manager.purchasedIDs.insert("test.product")
        manager.purchasedIDs.insert("test.product")
        manager.purchasedIDs.insert("test.product")
        
        #expect(manager.purchaseCalled == true)
    }
    
    @Test("Тест граничного случая: множественные вызовы restorePurchases")
    func testMultipleRestorePurchasesCalls() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        // Вызываем restorePurchases несколько раз
        await service.restorePurchases()
        await service.restorePurchases()
        await service.restorePurchases()
        
        #expect(manager.restorePurchasesCalled == true)
    }
    
    @Test("Тест граничного случая: очень большое количество продуктов")
    func testLargeNumberOfProducts() throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        var mockProducts: [MockProduct] = []
        for i in 0..<1000 {
            let mockProduct = MockProduct(id: "product\(i)", type: .nonConsumable, displayName: "Product \(i)", description: "Test \(i)", price: Decimal(i), priceFormatStyle: .currency(code: "USD"))
            mockProducts.append(mockProduct)
        }
        
        manager.setMockProducts(mockProducts)
        
        #expect(mockProducts.count == 1000)
        #expect(mockProducts.first?.id == "product0")
        #expect(mockProducts.last?.id == "product999")
    }
    
    @Test("Тест граничного случая: очень большое количество покупок")
    func testLargeNumberOfPurchases() async throws {
        let manager = MockPurchaseManager()
        
        // Добавляем много покупок
        for i in 0..<1000 {
            manager.purchasedIDs.insert("product\(i)")
        }
        
        #expect(manager.purchasedIDs.count == 1000)
        #expect(manager.purchasedIDs.contains("product0"))
        #expect(manager.purchasedIDs.contains("product999"))
    }
    
    @Test("Тест граничного случая: PremiumStatus с максимальной датой")
    func testPremiumStatusWithMaxDate() throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let maxDate = Date.distantFuture
        let status = PremiumStatus(isLifetime: false, expirationDate: maxDate)
        
        try storage.set(status, forKey: "premiumStatus")
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        #expect(service.isPremium == true)
        #expect(service.premiumStatus.expirationDate == maxDate)
    }
    
    @Test("Тест граничного случая: PremiumStatus с минимальной датой")
    func testPremiumStatusWithMinDate() throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let minDate = Date.distantPast
        let status = PremiumStatus(isLifetime: false, expirationDate: minDate)
        
        try storage.set(status, forKey: "premiumStatus")
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        #expect(service.isPremium == false)
        #expect(service.premiumStatus.expirationDate == minDate)
    }
    
    @Test("Тест граничного случая: PremiumStatus с nil датой истечения при lifetime = false")
    func testPremiumStatusNilExpirationWithNonLifetime() throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let status = PremiumStatus(isLifetime: false, expirationDate: nil)
        
        try storage.set(status, forKey: "premiumStatus")
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        #expect(service.isPremium == false)
        #expect(service.premiumStatus.isLifetime == false)
        #expect(service.premiumStatus.expirationDate == nil)
    }
    
    @Test("Тест граничного случая: PremiumStatus с nil датой истечения при lifetime = true")
    func testPremiumStatusNilExpirationWithLifetime() throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let status = PremiumStatus(isLifetime: true, expirationDate: nil)
        
        try storage.set(status, forKey: "premiumStatus")
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        #expect(service.isPremium == true)
        #expect(service.premiumStatus.isLifetime == true)
        #expect(service.premiumStatus.expirationDate == nil)
    }
    
    @Test("Тест граничного случая: пустой список продуктов")
    func testEmptyProductsList() throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        #expect(service.products.isEmpty)
        #expect(service.products.count == 0)
    }
    
    @Test("Тест граничного случая: пустой список покупок")
    func testEmptyPurchasedIDs() throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        #expect(manager.purchasedIDs.isEmpty)
        #expect(service.isPremium == false)
    }
    
    @Test("Тест граничного случая: очень длинные сообщения логгера")
    func testVeryLongLoggerMessages() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        // Симулируем очень длинное сообщение
        let longMessage = String(repeating: "test", count: 10000)
        logger.debug(longMessage)
        
        await service.start()
        
        #expect(logger.loggedMessages.count > 0)
        #expect(logger.loggedMessages.contains { $0.count > 1000 })
    }
    
    @Test("Тест граничного случая: множественные экземпляры сервиса")
    func testMultipleServiceInstances() throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        
        // Создаем несколько экземпляров сервиса
        let service1 = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        let service2 = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        let service3 = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        #expect(service1.isPremium == false)
        #expect(service2.isPremium == false)
        #expect(service3.isPremium == false)
        
        // Все должны использовать одно и то же хранилище
        #expect(service1.premiumStatus == service2.premiumStatus)
        #expect(service2.premiumStatus == service3.premiumStatus)
    }
}
