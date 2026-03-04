//
//  OfflineManager.swift
//  Campus Explorer
//
//  Manages offline mode, network monitoring, and data caching
//

import Foundation
import Network
import Observation

@Observable
class OfflineManager {
    var isConnected: Bool = true
    var isOfflineModeEnabled: Bool = false // Manual override
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private let userDefaults = UserDefaults.standard
    
    init() {
        startMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    // MARK: - Caching
    func cacheData<T: Codable>(_ data: T, forKey key: String) {
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: "offline_cache_\(key)")
        }
    }
    
    func loadCachedData<T: Codable>(forKey key: String, type: T.Type) -> T? {
        if let data = userDefaults.data(forKey: "offline_cache_\(key)") {
            return try? JSONDecoder().decode(type, from: data)
        }
        return nil
    }
    
    func clearCache() {
        // In a real app, we'd list all keys or use a specific suite.
        // For now, we assume simple key management or specific clears.
    }
}
