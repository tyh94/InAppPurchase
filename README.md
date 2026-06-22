# 📦 InAppPurchase

Менеджер покупок на **StoreKit 2** для iOS 18+ в виде Swift Package.
Поддерживает:
- Загрузку продуктов по переданным идентификаторам
- Покупку и восстановление
- Хранение списка купленных товаров
- Проверку прав доступа при старте приложения

---

## 🛠 Установка

1. В Xcode:
   `File` → `Add Packages...` → вставь URL репозитория пакета → `Add Package`.
   
2. Убедись, что у тебя в проекте включён **In-App Purchase**:
   `Signing & Capabilities` → `+ Capability` → **In-App Purchase**.

---

## 🚀 Быстрый старт

### 1. Импорт и инициализация PremiumService

```swift
import SwiftUI
import InAppPurchase

@main
struct MyApp: App {
    @StateObject private var premium = PremiumService(
        productIDs: [
            "com.yourapp.premium.lifetime",
            "com.yourapp.premium.subscription"
        ],
        // Для примера. В продакшене передайте ваше хранилище,
        // реализующее протокол `KeyValueStorage`.
        storage: KeyValueStorageMock()
    )
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(premium)
                .task {
                    await premium.start()
                }
        }
    }
}
```

### 2. Использование во вью

```swift
struct ContentView: View {
    @EnvironmentObject var premium: PremiumService
    
    var body: some View {
        VStack(spacing: 16) {
            Text(premium.isPremium ? "Premium активен" : "Бесплатная версия")
                .font(.headline)
            
            List(premium.products, id: \.id) { product in
                HStack {
                    Text(product.displayName)
                    Spacer()
                    Button("Купить") {
                        Task { await premium.purchase(product) }
                    }
                }
            }
            .frame(height: 250)
            
            Button("Восстановить покупки") {
                Task { await premium.restorePurchases() }
            }
        }
        .padding()
    }
}
```
