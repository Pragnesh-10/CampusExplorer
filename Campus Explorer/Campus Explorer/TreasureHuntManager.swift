//
//  TreasureHuntManager.swift
//  Campus Explorer
//
//  Manages gamified AR treasure hunt
//

import Foundation
import CoreLocation
import Observation
import Combine

struct TreasureItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let coordinate: CodableCoordinate
    let points: Int
    var isCollected: Bool
    var hint: String
}

@Observable
class TreasureHuntManager {
    var items: [TreasureItem] = []
    var collectedItemsCount: Int = 0
    var totalPoints: Int = 0
    var nearestItem: TreasureItem?
    var distanceToNearest: Double = 0
    
    private let userDefaults = UserDefaults.standard
    private let storageKey = "treasure_items"
    
    init() {
        loadItems()
    }
    
    func checkProximity(userLocation: CLLocation) {
        // Find nearest uncollected item
        let uncollected = items.filter { !$0.isCollected }
        
        var minDistance: Double = .infinity
        var nearest: TreasureItem?
        
        for item in uncollected {
            let itemLoc = CLLocation(latitude: item.coordinate.latitude, longitude: item.coordinate.longitude)
            let dist = userLocation.distance(from: itemLoc)
            
            if dist < minDistance {
                minDistance = dist
                nearest = item
            }
        }
        
        nearestItem = nearest
        distanceToNearest = minDistance
    }
    
    func collectItem(_ item: TreasureItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isCollected = true
            collectedItemsCount += 1
            totalPoints += item.points
            saveItems()
        }
    }
    
    private func loadItems() {
        if let data = userDefaults.data(forKey: storageKey),
           let savedContainer = try? JSONDecoder().decode([TreasureItem].self, from: data) {
            items = savedContainer
            recalculateStats()
        } else {
            generateSampleItems()
        }
    }
    
    private func saveItems() {
        if let data = try? JSONEncoder().encode(items) {
            userDefaults.set(data, forKey: storageKey)
        }
    }
    
    private func recalculateStats() {
        collectedItemsCount = items.filter { $0.isCollected }.count
        totalPoints = items.filter { $0.isCollected }.reduce(0) { $0 + $1.points }
    }
    
    private func generateSampleItems() {
        // Generate items around a central point (mock campus)
        let center = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // Default SF
        
        items = [
            TreasureItem(id: UUID(), name: "Golden Compass", description: "Navigational relic found near the library.", coordinate: CodableCoordinate(center.offset(lat: 0.001, long: 0.001)), points: 100, isCollected: false, hint: "Look near the books."),
            TreasureItem(id: UUID(), name: "Ancient Scroll", description: "Hidden knowledge from the founders.", coordinate: CodableCoordinate(center.offset(lat: -0.001, long: 0.002)), points: 150, isCollected: false, hint: "Near the old oak tree."),
            TreasureItem(id: UUID(), name: "Crystal Prism", description: "Reflects the light of wisdom.", coordinate: CodableCoordinate(center.offset(lat: 0.002, long: -0.001)), points: 200, isCollected: false, hint: "By the fountain."),
            TreasureItem(id: UUID(), name: "Bronze Key", description: "Unlocks the gates of success.", coordinate: CodableCoordinate(center.offset(lat: -0.002, long: -0.002)), points: 120, isCollected: false, hint: "Under the archway.")
        ]
        saveItems()
    }
}

// Helper extension for offset
extension CLLocationCoordinate2D {
    func offset(lat: Double, long: Double) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude + lat, longitude: self.longitude + long)
    }
}
