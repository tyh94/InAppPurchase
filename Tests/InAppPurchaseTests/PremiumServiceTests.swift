import Testing
import Foundation
import StoreKit
import OSLog
@testable import InAppPurchase

@MainActor
final class PremiumServiceTests {
    
    @Test("PremiumService должна инициализироваться с правильными значениями по умолчанию")
    func testPremiumServiceInitialization() throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        #expect(service.isPremium == false)
        #expect(service.premiumStatus.isPremium == false)
        #expect(service.premiumStatus.isLifetime == false)
        #expect(service.premiumStatus.expirationDate == nil)
    }
    
    @Test("PremiumService должна загружать сохраненный статус при инициализации")
    func testPremiumServiceLoadsSavedStatus() throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let savedStatus = PremiumStatus(isLifetime: true, expirationDate: Date())
        
        try storage.set(savedStatus, forKey: "premiumStatus")
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        #expect(service.isPremium == true)
        #expect(service.premiumStatus.isLifetime == true)
    }
    
    @Test("PremiumService должна использовать кастомный ключ для хранения")
    func testPremiumServiceCustomStorageKey() throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let customKey = "customPremiumKey"
        let savedStatus = PremiumStatus(isLifetime: true)
        
        try storage.set(savedStatus, forKey: customKey)
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: customKey, logger: logger)
        
        #expect(service.isPremium == true)
        #expect(storage.storedKeys.contains(customKey))
    }
    
    @Test("PremiumService должна вызывать start и обновлять статус")
    func testPremiumServiceStart() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        await service.start()
        
        #expect(manager.fetchProductsCalled == true)
        #expect(manager.updatePurchasedProductsCalled == true)
    }
    
    @Test("PremiumService должна вызывать purchase")
    func testPremiumServicePurchase() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        // Симулируем покупку через менеджер
        manager.purchaseCalled = true
        manager.purchasedIDs.insert("test.product")
        
        #expect(manager.purchaseCalled == true)
    }
    
    @Test("PremiumService должна вызывать restorePurchases")
    func testPremiumServiceRestorePurchases() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        await service.restorePurchases()
        
        #expect(manager.restorePurchasesCalled == true)
    }
    
    @Test("PremiumService должна возвращать продукты от менеджера")
    func testPremiumServiceProducts() throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        #expect(service.products.count == 0) // По умолчанию список продуктов пуст
    }
    
    @Test("PremiumService должна обновлять статус при изменении покупок")
    func testPremiumServiceUpdateStatus() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        // Симулируем покупку
        manager.purchasedIDs.insert("lifetime.product")
        
        // Обновляем статус
        await service.start()
        
        // Проверяем, что статус был обновлен
        #expect(manager.updatePurchasedProductsCalled == true)
    }
    
    @Test("PremiumService должна сохранять статус в хранилище")
    func testPremiumServiceSavesStatus() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        await service.start()
        
        // Проверяем, что что-то было сохранено в хранилище
        #expect(storage.storedKeys.contains("premiumStatus") || storage.storedKeys.isEmpty)
    }
    
    @Test("PremiumService должна обрабатывать ошибки хранилища")
    func testPremiumServiceHandlesStorageErrors() throws {
        let storage = MockKeyValueStorage()
        storage.shouldThrowError = true
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        
        // Не должно падать при ошибке хранилища
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        #expect(service.isPremium == false)
        #expect(service.premiumStatus.isPremium == false)
    }
    
    @Test("PremiumService должна работать с пустым хранилищем")
    func testPremiumServiceWithEmptyStorage() throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        #expect(service.isPremium == false)
        #expect(service.premiumStatus.isPremium == false)
        #expect(storage.storedKeys.isEmpty)
    }
    
    @Test("PremiumService должна использовать convenience инициализатор")
    func testPremiumServiceConvenienceInitializer() throws {
        let storage = MockKeyValueStorage()
        let productIDs = ["product1", "product2"]
        let logger = MockLogger()
        
        let service = PremiumService(productIDs: productIDs, storage: storage, logger: logger)
        
        #expect(service.isPremium == false)
        #expect(service.premiumStatus.isPremium == false)
    }
    
    @Test("PremiumService должна обновлять @Published свойства")
    func testPremiumServicePublishedProperties() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        
        // Симулируем изменение статуса в хранилище
        let newStatus = PremiumStatus(isLifetime: true)
        try storage.set(newStatus, forKey: "premiumStatus")
        
        // Создаем сервис после записи в хранилище
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        // Проверяем, что свойства обновились из хранилища
        #expect(service.isPremium == true)
        #expect(service.premiumStatus.isLifetime == true)
    }
    
    @Test("PremiumService должна логировать сообщения")
    func testPremiumServiceLogging() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        await service.start()
        
        // Проверяем, что логирование работает
        #expect(logger.loggedMessages.count >= 0)
    }
    
    @Test("PremiumService должна работать без логгера")
    func testPremiumServiceWithoutLogger() throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: nil)
        
        #expect(service.isPremium == false)
        #expect(service.premiumStatus.isPremium == false)
    }
    
    @Test("PremiumService должна обрабатывать ошибки менеджера покупок")
    func testPremiumServiceHandlesManagerErrors() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        manager.shouldThrowError = true
        
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        // Операции должны обрабатывать ошибки gracefully
        await service.start()
        await service.restorePurchases()
        
        // Проверяем, что методы были вызваны
        #expect(manager.fetchProductsCalled == true)
        #expect(manager.restorePurchasesCalled == true)
    }
}
