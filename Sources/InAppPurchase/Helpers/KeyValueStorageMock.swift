//
//  KeyValueStorageMock.swift
//  InAppPurchase
//
//  Created by Татьяна Макеева on 21.08.2025.
//

import Foundation

public struct KeyValueStorageMock: KeyValueStorage {
    let objects: [String: Data]
    
    public init(objects: [String: Data] = [:]) {
        self.objects = objects
    }
    
    public func set<T>(_ value: T, forKey key: String) throws where T : Decodable, T : Encodable {
        
    }
    
    public func object<T>(forKey key: String) throws -> T? where T : Decodable, T : Encodable {
        guard let data = objects[key] else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    public func removeObject(forKey key: String) throws {
        
    }
}
