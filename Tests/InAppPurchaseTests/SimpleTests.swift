import Testing
import Foundation
@testable import InAppPurchase

@MainActor
final class SimpleTests {
    
    @Test("Простой тест: PremiumStatus инициализация")
    func testPremiumStatusInitialization() throws {
        let status = PremiumStatus()
        #expect(status.isPremium == false)
        #expect(status.isLifetime == false)
        #expect(status.expirationDate == nil)
    }
    
    @Test("Простой тест: PremiumStatus с lifetime")
    func testPremiumStatusLifetime() throws {
        let status = PremiumStatus(isLifetime: true)
        #expect(status.isPremium == true)
        #expect(status.isLifetime == true)
        #expect(status.expirationDate == nil)
    }
    
    @Test("Простой тест: PremiumStatus с будущей датой")
    func testPremiumStatusFutureDate() throws {
        let futureDate = Date().addingTimeInterval(3600) // +1 час
        let status = PremiumStatus(isLifetime: false, expirationDate: futureDate)
        #expect(status.isPremium == true)
        #expect(status.isLifetime == false)
        #expect(status.expirationDate == futureDate)
    }
    
    @Test("Простой тест: PremiumStatus с прошедшей датой")
    func testPremiumStatusPastDate() throws {
        let pastDate = Date().addingTimeInterval(-3600) // -1 час
        let status = PremiumStatus(isLifetime: false, expirationDate: pastDate)
        #expect(status.isPremium == false)
        #expect(status.isLifetime == false)
        #expect(status.expirationDate == pastDate)
    }
    
    @Test("Простой тест: MockKeyValueStorage")
    func testMockStorage() throws {
        let storage = MockKeyValueStorage()
        let testData = "test"
        
        try storage.set(testData, forKey: "testKey")
        let retrieved: String? = try storage.object(forKey: "testKey")
        
        #expect(retrieved == testData)
        #expect(storage.storedKeys.contains("testKey"))
    }
    
    @Test("Простой тест: MockPurchaseManager")
    func testMockPurchaseManager() async throws {
        let manager = MockPurchaseManager()
        
        await manager.fetchProducts()
        await manager.restorePurchases()
        
        #expect(manager.fetchProductsCalled == true)
        #expect(manager.restorePurchasesCalled == true)
    }
    
    @Test("Простой тест: MockLogger")
    func testMockLogger() throws {
        let logger = MockLogger()
        
        logger.log("Test message", level: .debug, file: "test", function: "test", line: 1)
        
        #expect(logger.loggedMessages.count == 1)
        #expect(logger.loggedMessages.contains("Test message"))
    }
    
    @Test("Простой тест: PremiumService инициализация")
    func testPremiumServiceInitialization() throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        #expect(service.isPremium == false)
        #expect(service.premiumStatus.isPremium == false)
        #expect(service.products.isEmpty)
    }
    
    @Test("Простой тест: PremiumService start")
    func testPremiumServiceStart() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        await service.start()
        
        #expect(manager.fetchProductsCalled == true)
        #expect(manager.updatePurchasedProductsCalled == true)
    }
    
    @Test("Простой тест: PremiumService restorePurchases")
    func testPremiumServiceRestorePurchases() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        await service.restorePurchases()
        
        #expect(manager.restorePurchasesCalled == true)
    }
}

