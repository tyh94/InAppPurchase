//
//  PremiumStatus.swift
//  InAppPurchase
//
//  Created by Татьяна Макеева on 20.08.2025.
//

import Foundation

public struct PremiumStatus: Codable, Equatable {
    public let isLifetime: Bool
    public let expirationDate: Date?
    
    public init(
        isLifetime: Bool = false,
        expirationDate: Date? = nil
    ) {
        self.isLifetime = isLifetime
        self.expirationDate = expirationDate
    }
    
    public var isPremium: Bool {
        if isLifetime {
            return true
        }
        if let expirationDate, expirationDate > Date() {
            return true
        }
        return false
    }
}
