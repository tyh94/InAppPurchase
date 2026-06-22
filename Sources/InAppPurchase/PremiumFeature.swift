//
//  PremiumFeature.swift
//  InAppPurchase
//
//  Created by Татьяна Макеева on 22.06.2026.
//

import Foundation

/// Описание одной фичи premium-версии.
/// Создаётся на стороне приложения и передаётся в PremiumView.
public struct PremiumFeature: Identifiable, Sendable {
    public let id: String
    public let icon: String
    public let title: String
    public let description: String

    public init(icon: String, title: String, description: String) {
        self.id = title
        self.icon = icon
        self.title = title
        self.description = description
    }
}

