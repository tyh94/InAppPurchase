import Foundation
import StoreKit
@testable import InAppPurchase
import Combine

// MARK: - Mock PurchaseManager

public final class MockPurchaseManager: PurchaseManaging, @unchecked Sendable {
    @Published public var purchasedIDs: Set<String> = []
    
    public var purchasedIDsPublisher: AnyPublisher<Set<String>, Never> {
        $purchasedIDs.eraseToAnyPublisher()
    }
    
    public var products: [Product] = []
    
    public var fetchProductsCalled = false
    public var purchaseCalled = false
    public var restorePurchasesCalled = false
    public var updatePurchasedProductsCalled = false
    
    public var shouldThrowError = false
    public var errorToThrow: Error = NSError(domain: "TestError", code: 1, userInfo: nil)
    
    public init() {}
    
    public func fetchProducts() async {
        fetchProductsCalled = true
        if shouldThrowError {
            return
        }
        // Минимальная задержка для симуляции реальной работы
        try? await Task.sleep(for: .milliseconds(1))
    }
    
    public func purchase(_ product: Product) async {
        purchaseCalled = true
        if shouldThrowError {
            return
        }
        purchasedIDs.insert(product.id)
        // Минимальная задержка для симуляции реальной работы
        try? await Task.sleep(for: .milliseconds(1))
    }
    
    public func restorePurchases() async {
        restorePurchasesCalled = true
        if shouldThrowError {
            return
        }
        // Минимальная задержка для симуляции реальной работы
        try? await Task.sleep(for: .milliseconds(1))
    }
    
    public func updatePurchasedProducts() async {
        updatePurchasedProductsCalled = true
        if shouldThrowError {
            return
        }
        // Минимальная задержка для симуляции реальной работы
        try? await Task.sleep(for: .milliseconds(1))
    }
    
    // Метод для установки мок продуктов
    public func setMockProducts(_ mockProducts: [MockProduct]) {
        // В реальных тестах здесь можно создать реальные Product объекты
        // или использовать StoreKit Test Configuration
        self.products = []
    }
    
    // Метод для симуляции успешной покупки
    public func simulateSuccessfulPurchase(productID: String) {
        purchasedIDs.insert(productID)
    }
    
    // Метод для проверки, куплен ли продукт
    public func isProductPurchased(_ productID: String) -> Bool {
        return purchasedIDs.contains(productID)
    }
}

// MARK: - Mock KeyValueStorage

public final class MockKeyValueStorage: KeyValueStorage {
    private var storage: [String: Data] = [:]
    public var shouldThrowError = false
    public var errorToThrow: Error = NSError(domain: "StorageError", code: 1, userInfo: nil)
    
    public init() {}
    
    public func set<T: Codable>(_ value: T, forKey key: String) throws {
        if shouldThrowError {
            throw errorToThrow
        }
        let data = try JSONEncoder().encode(value)
        storage[key] = data
    }
    
    public func object<T: Codable>(forKey key: String) throws -> T? {
        if shouldThrowError {
            throw errorToThrow
        }
        guard let data = storage[key] else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    public func removeObject(forKey key: String) throws {
        if shouldThrowError {
            throw errorToThrow
        }
        storage.removeValue(forKey: key)
    }
    
    public func clear() {
        storage.removeAll()
    }
    
    public var storedKeys: [String] {
        Array(storage.keys)
    }
}

// MARK: - Mock Logger

public final class MockLogger: Logger, @unchecked Sendable {
    public var loggedMessages: [String] = []
    
    public func log(_ message: String, level: InAppPurchase.LogLevel, file: String, function: String, line: Int) {
        loggedMessages.append(message)
    }
}

// MARK: - Mock Product

public struct MockProduct {
    public let id: String
    public let type: Product.ProductType
    public let displayName: String
    public let description: String
    public let price: Decimal
    public let priceFormatStyle: Decimal.FormatStyle.Currency
    
    public init(
        id: String = "test.product",
        type: Product.ProductType = .nonConsumable,
        displayName: String = "Test Product",
        description: String = "Test Description",
        price: Decimal = 0.99,
        priceFormatStyle: Decimal.FormatStyle.Currency = .currency(code: "USD")
    ) {
        self.id = id
        self.type = type
        self.displayName = displayName
        self.description = description
        self.price = price
        self.priceFormatStyle = priceFormatStyle
    }
}

// MARK: - Mock Transaction

public extension Transaction {
    static func mock(
        id: UInt64 = 1,
        productID: String = "test.product",
        productType: Product.ProductType = .nonConsumable,
        purchaseDate: Date = Date(),
        expirationDate: Date? = nil,
        revocationDate: Date? = nil
    ) -> Transaction {
        // В реальном тестировании используйте StoreKit Test Configuration
        fatalError("Mock Transaction creation not implemented - use StoreKit Test Configuration in real tests")
    }
}
