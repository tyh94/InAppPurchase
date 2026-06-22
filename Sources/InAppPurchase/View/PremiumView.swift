//
//  File.swift
//  InAppPurchase
//
//  Created by Татьяна Макеева on 22.06.2026.
//

import StoreKit
import SwiftUI

/// Экран покупки premium (non-consumable).
///
/// Требует `PremiumService` в `@Environment`.
/// Список фич передаётся снаружи — библиотека не знает, что именно открывает premium в конкретном приложении.
///
/// Использование:
/// ```swift
/// PremiumView(features: [
///     PremiumFeature(icon: "wand.and.stars", title: "Умный импорт", description: "Распознавание рецептов через ИИ"),
///     PremiumFeature(icon: "icloud", title: "Облачный бэкап", description: "Синхронизация через Google Drive"),
/// ])
/// .environment(premiumService)
/// ```
public struct PremiumView: View {
    @Environment(PremiumService.self) private var premiumService
    @Environment(\.dismiss) private var dismiss
    
    private let title: String
    private let subtitle: String
    private let features: [PremiumFeature]
    
    public init(
        title: String,
        subtitle: String,
        features: [PremiumFeature]
    ) {
        self.title = title
        self.subtitle = subtitle
        self.features = features
    }
    
    public var body: some View {
        List {
            headerSection
            if !features.isEmpty {
                featuresSection
            }
            actionSection
        }
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: premiumService.isPremium) { oldValue, newValue in
            if newValue {
                dismiss()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.orange)

                VStack(spacing: 6) {
                    Text(title)
                        .font(.title2.bold())
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    }

    // MARK: - Features

    private var featuresSection: some View {
        Section {
            ForEach(features) { feature in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: feature.icon)
                        .font(.title3)
                        .foregroundStyle(.orange)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.subheadline.weight(.semibold))
                        Text(feature.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Actions

    @ViewBuilder
    private var actionSection: some View {
        if premiumService.isPremium {
            purchasedSection
        } else {
            buySection
        }
    }

    private var purchasedSection: some View {
        Section {
            Label {
                Text("premium.status.purchased", bundle: .module)
                    .foregroundStyle(.primary)
            } icon: {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.orange)
            }
        } footer: {
            Text("premium.purchased.footer", bundle: .module)
        }
    }

    @ViewBuilder
    private var buySection: some View {
        Section {
            if premiumService.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if !premiumService.products.isEmpty {
                ForEach(premiumService.products) { product in
                    productRow(product)
                }
            } else {
                Button {
                    Task {
                        await premiumService.start()
                    }
                } label: {
                    Label(
                        String(localized: "premium.retry", bundle: .module),
                        systemImage: "arrow.clockwise"
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }

        Section {
            Button {
                Task {
                    await premiumService.restorePurchases()
                }
            } label: {
                Text("premium.restore", bundle: .module)
                    .frame(maxWidth: .infinity)
            }
            .disabled(premiumService.isLoading)
            .foregroundStyle(.secondary)
        }
    }

    private func productRow(_ product: Product) -> some View {
        Button {
            Task {
                await premiumService.purchase(product)
            }
        } label: {
            HStack {
                Text(product.displayName)
                    .foregroundStyle(.primary)
                    .bold()
                Spacer()
                Text(product.displayPrice)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PremiumView(
            title: "Title",
            subtitle: "Subtitle",
            features: [
            PremiumFeature(icon: "wand.and.stars", title: "AI Import", description: "Parse recipes with AI"),
            PremiumFeature(icon: "icloud", title: "Cloud Backup", description: "Sync via Google Drive"),
        ])
    }
    .environment(PremiumService.preview(isPremium: false))
}
