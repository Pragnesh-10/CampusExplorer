//
//  KeychainHelper.swift
//  Campus Explorer
//
//  Securely stores sensitive data using Keychain Services
//

import Foundation
import Security

class KeychainHelper {
    static let standard = KeychainHelper()
    private init() {}
    
    // MARK: - Save
    func save(_ data: Data, service: String, account: String) {
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ] as [String: Any]
        
        // Add or Update
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            let query = [
                kSecAttrService: service,
                kSecAttrAccount: account,
                kSecClass: kSecClassGenericPassword,
            ] as [String: Any]
            
            let attributesToUpdate = [kSecValueData: data] as [String: Any]
            
            SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        }
    }
    
    // MARK: - Read
    func read(service: String, account: String) -> Data? {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true
        ] as [String: Any]
        
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        
        return result as? Data
    }
    
    // MARK: - Delete
    func delete(service: String, account: String) {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
        ] as [String: Any]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Helpers
    func save<T: Codable>(_ item: T, service: String, account: String) {
        do {
            let data = try JSONEncoder().encode(item)
            save(data, service: service, account: account)
        } catch {
            print("Error encoding item for Keychain: \(error)")
        }
    }
    
    func read<T: Codable>(service: String, account: String, type: T.Type) -> T? {
        guard let data = read(service: service, account: account) else { return nil }
        
        do {
            let item = try JSONDecoder().decode(type, from: data)
            return item
        } catch {
            print("Error decoding item from Keychain: \(error)")
            return nil
        }
    }
}
