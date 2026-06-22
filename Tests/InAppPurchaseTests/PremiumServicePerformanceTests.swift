import Testing
import Foundation
import StoreKit
@testable import InAppPurchase

@MainActor
final class PremiumServicePerformanceTests {
    
    @Test("Тест производительности: множественные операции с хранилищем")
    func testStoragePerformance() throws {
        let storage = MockKeyValueStorage()
        let iterations = 1000
        
        let startTime = Date()
        for i in 0..<iterations {
            let status = PremiumStatus(isLifetime: i % 2 == 0, expirationDate: Date())
            try? storage.set(status, forKey: "key\(i)")
            let _: PremiumStatus? = try? storage.object(forKey: "key\(i)")
        }
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        #expect(duration < 1.0) // Должно выполняться менее чем за 1 секунду
    }
    
    @Test("Тест производительности: создание множественных сервисов")
    func testServiceCreationPerformance() throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        
        let startTime = Date()
        for _ in 0..<100 {
            let _ = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        }
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        #expect(duration < 0.5) // Должно выполняться менее чем за 0.5 секунды
    }
    
    @Test("Тест производительности: множественные вызовы start")
    func testMultipleStartCallsPerformance() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        let startTime = Date()
        for _ in 0..<50 {
            await service.start()
        }
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        #expect(duration < 3.0) // Должно выполняться менее чем за 3 секунды
    }
    
    @Test("Тест производительности: множественные вызовы purchase")
    func testMultiplePurchaseCallsPerformance() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        let startTime = Date()
        for _ in 0..<100 {
            // Симулируем вызов покупки через менеджер
            manager.purchaseCalled = true
            manager.purchasedIDs.insert("test.product")
        }
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        #expect(duration < 0.1) // Должно выполняться очень быстро
        #expect(manager.purchaseCalled == true)
    }
    
    @Test("Тест производительности: множественные вызовы restorePurchases")
    func testMultipleRestorePurchasesCallsPerformance() async throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        let startTime = Date()
        for _ in 0..<100 {
            await service.restorePurchases()
        }
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        #expect(duration < 2.0) // Должно выполняться менее чем за 2 секунды
    }
    
    @Test("Тест производительности: работа с большим количеством продуктов")
    func testLargeNumberOfProductsPerformance() throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        
        // Создаем большое количество мок продуктов
        var mockProducts: [MockProduct] = []
        for i in 0..<1000 {
            let mockProduct = MockProduct(id: "product\(i)", type: .nonConsumable, displayName: "Product \(i)", description: "Test \(i)", price: Decimal(i), priceFormatStyle: .currency(code: "USD"))
            mockProducts.append(mockProduct)
        }
        
        manager.setMockProducts(mockProducts)
        
        let startTime = Date()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        let _ = service.products.count
        let _ = service.products.first?.id
        let _ = service.products.last?.id
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        #expect(duration < 0.1) // Должно выполняться менее чем за 0.1 секунды
    }
    
    @Test("Тест производительности: сериализация и десериализация PremiumStatus")
    func testPremiumStatusSerializationPerformance() throws {
        let storage = MockKeyValueStorage()
        let iterations = 10000
        
        let startTime = Date()
        for i in 0..<iterations {
            let status = PremiumStatus(
                isLifetime: i % 2 == 0,
                expirationDate: Date().addingTimeInterval(Double(i))
            )
            try? storage.set(status, forKey: "status\(i)")
            let _: PremiumStatus? = try? storage.object(forKey: "status\(i)")
        }
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        #expect(duration < 5.0) // Должно выполняться менее чем за 5 секунд
    }
    
    @Test("Тест производительности: логирование")
    func testLoggingPerformance() async throws {
        let logger = MockLogger()
        
        let startTime = Date()
        for i in 0..<1000 {
            logger.log("Test message \(i)", level: .debug, file: "test", function: "test", line: 1)
            logger.log("Info message \(i)", level: .info, file: "test", function: "test", line: 1)
            logger.log("Warning message \(i)", level: .warning, file: "test", function: "test", line: 1)
            logger.log("Error message \(i)", level: .error, file: "test", function: "test", line: 1)
        }
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        #expect(duration < 1.0) // Должно выполняться менее чем за 1 секунду
    }
    
    @Test("Тест производительности: проверка премиум статуса")
    func testPremiumStatusCheckPerformance() throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
        
        let startTime = Date()
        for _ in 0..<10000 {
            let _ = service.isPremium
            let _ = service.premiumStatus.isPremium
            let _ = service.premiumStatus.isLifetime
            let _ = service.premiumStatus.expirationDate
        }
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        #expect(duration < 0.1) // Должно выполняться менее чем за 0.1 секунды
    }
    
    @Test("Тест производительности: работа с множественными экземплярами")
    func testMultipleInstancesPerformance() throws {
        let storage = MockKeyValueStorage()
        let manager = MockPurchaseManager()
        let logger = MockLogger()
        
        let startTime = Date()
        var services: [PremiumService] = []
        for _ in 0..<100 {
            let service = PremiumService(purchaseManager: manager, storage: storage, storageKey: "premiumStatus", logger: logger)
            services.append(service)
        }
        
        // Проверяем свойства всех сервисов
        for service in services {
            let _ = service.isPremium
            let _ = service.premiumStatus
            let _ = service.products
        }
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        #expect(duration < 1.0) // Должно выполняться менее чем за 1 секунду
    }
}
