//
//  PremiumStatusBadge.swift
//  InAppPurchase
//
//  Created by Татьяна Макеева on 22.06.2026.
//

import SwiftUI

/// Компактный индикатор статуса premium — для строки в экране "О приложении".
///
/// Использование:
/// ```swift
/// NavigationLink { PremiumView() } label: {
///     HStack {
///         Label("Status", systemImage: "star.circle.fill")
///         Spacer()
///         PremiumStatusBadge()
///     }
/// }
/// ```
public struct PremiumStatusBadge: View {
    @Environment(PremiumService.self) private var premium

    public init() {}

    @ViewBuilder
    public var body: some View {
        if premium.isLoading {
            ProgressView()
                .controlSize(.small)
        } else if premium.isPremium {
            Label {
                Text("premium.status.purchased", bundle: .module)
            } icon: {
                Image(systemName: "checkmark.seal.fill")
            }
            .font(.subheadline)
            .foregroundStyle(.orange)
            .labelStyle(.titleAndIcon)
        } else {
            Text("premium.status.free", bundle: .module)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    List {
        NavigationLink {
            Text("")
        } label: {
            HStack {
                Label("Status", systemImage: "star.circle.fill")
                Spacer()
                PremiumStatusBadge()
            }
        }
    }
    .environment(PremiumService.preview(isPremium: true))
}

