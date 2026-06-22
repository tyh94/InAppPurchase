//
//  KeyValueStorage.swift
//  InAppPurchase
//
//  Created by Татьяна Макеева on 20.08.2025.
//

import Foundation

public protocol KeyValueStorage {
    func set<T: Codable>(_ value: T, forKey key: String) throws
    func object<T: Codable>(forKey key: String) throws -> T?
    func removeObject(forKey key: String) throws
}
