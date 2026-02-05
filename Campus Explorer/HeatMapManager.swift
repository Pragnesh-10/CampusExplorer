//
//  HeatMapManager.swift
//  Campus Explorer
//
//  Manages heat map and fog of war data
//

import SwiftUI
import MapKit
import CoreLocation
import Observation

// MARK: - Heat Map Data Point
struct HeatMapPoint: Identifiable, Codable {
    let id: UUID
    let coordinate: CodableCoordinate
    let timestamp: Date
    var intensity: Int  // Number of visits
    
    init(coordinate: CLLocationCoordinate2D, timestamp: Date = Date(), intensity: Int = 1) {
        self.id = UUID()
        self.coordinate = CodableCoordinate(coordinate)
        self.timestamp = timestamp
        self.intensity = intensity
    }
}

// MARK: - Codable Coordinate
struct CodableCoordinate: Codable {
    let latitude: Double
    let longitude: Double
    
    init(_ coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
    
    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Explored Region
struct ExploredRegion: Identifiable, Codable {
    let id: UUID
    let center: CodableCoordinate
    let radius: Double  // meters
    let exploredAt: Date
    
    init(center: CLLocationCoordinate2D, radius: Double = 50, exploredAt: Date = Date()) {
        self.id = UUID()
        self.center = CodableCoordinate(center)
        self.radius = radius
        self.exploredAt = exploredAt
    }
}

// MARK: - Point of Interest
struct PointOfInterest: Identifiable, Codable {
    let id: UUID
    var name: String
    var category: POICategory
    let coordinate: CodableCoordinate
    var isVisited: Bool
    var visitCount: Int
    var lastVisited: Date?
    var notes: String
    
    init(name: String, category: POICategory, coordinate: CLLocationCoordinate2D, notes: String = "") {
        self.id = UUID()
        self.name = name
        self.category = category
        self.coordinate = CodableCoordinate(coordinate)
        self.isVisited = false
        self.visitCount = 0
        self.lastVisited = nil
        self.notes = notes
    }
}

// MARK: - POI Category
enum POICategory: String, Codable, CaseIterable {
    case academic = "Academic"
    case dining = "Dining"
    case sports = "Sports"
    case library = "Library"
    case dorm = "Dormitory"
    case medical = "Medical"
    case parking = "Parking"
    case landmark = "Landmark"
    case custom = "Custom"
    
    var iconName: String {
        switch self {
        case .academic: return "building.columns.fill"
        case .dining: return "fork.knife"
        case .sports: return "sportscourt.fill"
        case .library: return "books.vertical.fill"
        case .dorm: return "bed.double.fill"
        case .medical: return "cross.fill"
        case .parking: return "car.fill"
        case .landmark: return "mappin.circle.fill"
        case .custom: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .academic: return .blue
        case .dining: return .orange
        case .sports: return .green
        case .library: return .purple
        case .dorm: return .pink
        case .medical: return .red
        case .parking: return .gray
        case .landmark: return .yellow
        case .custom: return .cyan
        }
    }
}

// MARK: - Heat Map Manager
@Observable
@MainActor
class HeatMapManager {
    var heatMapPoints: [HeatMapPoint] = []
    var exploredRegions: [ExploredRegion] = []
    var pointsOfInterest: [PointOfInterest] = []
    var totalExploredArea: Double = 0  // square meters
    var fogOfWarEnabled: Bool = true
    var heatMapVisible: Bool = false
    
    // Grid settings for heat map
    private let gridSize: Double = 20  // meters per grid cell
    private var visitedCells: Set<String> = []
    
    init() {
        loadData()
        setupDefaultPOIs()
    }
    
    // MARK: - Track Location
    func trackLocation(_ coordinate: CLLocationCoordinate2D) {
        // Add to heat map
        addHeatMapPoint(coordinate)
        
        // Add explored region
        addExploredRegion(coordinate)
        
        // Check POI visits
        checkPOIVisits(coordinate)
        
        // Save data
        saveData()
    }
    
    // MARK: - Heat Map Functions
    private func addHeatMapPoint(_ coordinate: CLLocationCoordinate2D) {
        let cellKey = getCellKey(for: coordinate)
        
        if let index = heatMapPoints.firstIndex(where: { getCellKey(for: $0.coordinate.clCoordinate) == cellKey }) {
            heatMapPoints[index].intensity += 1
        } else {
            let point = HeatMapPoint(coordinate: coordinate)
            heatMapPoints.append(point)
        }
    }
    
    private func getCellKey(for coordinate: CLLocationCoordinate2D) -> String {
        let latCell = Int(coordinate.latitude * 10000 / gridSize)
        let lonCell = Int(coordinate.longitude * 10000 / gridSize)
        return "\(latCell),\(lonCell)"
    }
    
    // MARK: - Fog of War Functions
    private func addExploredRegion(_ coordinate: CLLocationCoordinate2D) {
        let cellKey = getCellKey(for: coordinate)
        
        if !visitedCells.contains(cellKey) {
            visitedCells.insert(cellKey)
            let region = ExploredRegion(center: coordinate, radius: 50)
            exploredRegions.append(region)
            
            // Update total explored area
            totalExploredArea += Double.pi * 50 * 50  // πr²
        }
    }
    
    func isExplored(_ coordinate: CLLocationCoordinate2D) -> Bool {
        for region in exploredRegions {
            let distance = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
                .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
            if distance <= region.radius {
                return true
            }
        }
        return false
    }
    
    var explorationPercentage: Double {
        // Assuming campus is approximately 1 km²
        let campusArea: Double = 1_000_000  // square meters
        return min((totalExploredArea / campusArea) * 100, 100)
    }
    
    // MARK: - POI Functions
    private func setupDefaultPOIs() {
        guard pointsOfInterest.isEmpty else { return }
        
        // SRM University AP default POIs
        let srmCenter = CLLocationCoordinate2D(latitude: 16.4350, longitude: 80.5104)
        
        let defaultPOIs: [(String, POICategory, Double, Double)] = [
            ("Main Academic Block", .academic, 16.4355, 80.5110),
            ("Central Library", .library, 16.4348, 80.5095),
            ("Sports Complex", .sports, 16.4340, 80.5120),
            ("Food Court", .dining, 16.4360, 80.5100),
            ("Health Center", .medical, 16.4345, 80.5115),
            ("Student Hostel A", .dorm, 16.4365, 80.5090),
            ("Student Hostel B", .dorm, 16.4370, 80.5095),
            ("Main Entrance", .landmark, 16.4330, 80.5100),
            ("Parking Lot A", .parking, 16.4335, 80.5085),
            ("Auditorium", .landmark, 16.4352, 80.5108)
        ]
        
        for (name, category, lat, lon) in defaultPOIs {
            let poi = PointOfInterest(
                name: name,
                category: category,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
            )
            pointsOfInterest.append(poi)
        }
        
        saveData()
    }
    
    func addCustomPOI(name: String, category: POICategory, coordinate: CLLocationCoordinate2D, notes: String = "") {
        let poi = PointOfInterest(name: name, category: category, coordinate: coordinate, notes: notes)
        pointsOfInterest.append(poi)
        saveData()
    }
    
    func removePOI(_ poi: PointOfInterest) {
        pointsOfInterest.removeAll { $0.id == poi.id }
        saveData()
    }
    
    private func checkPOIVisits(_ coordinate: CLLocationCoordinate2D) {
        let visitRadius: Double = 30  // meters
        
        for i in pointsOfInterest.indices {
            let distance = CLLocation(latitude: pointsOfInterest[i].coordinate.latitude, longitude: pointsOfInterest[i].coordinate.longitude)
                .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
            
            if distance <= visitRadius {
                if !pointsOfInterest[i].isVisited {
                    pointsOfInterest[i].isVisited = true
                }
                pointsOfInterest[i].visitCount += 1
                pointsOfInterest[i].lastVisited = Date()
            }
        }
    }
    
    var visitedPOIsCount: Int {
        pointsOfInterest.filter { $0.isVisited }.count
    }
    
    // MARK: - Persistence
    private func saveData() {
        let encoder = JSONEncoder()
        
        if let heatData = try? encoder.encode(heatMapPoints) {
            UserDefaults.standard.set(heatData, forKey: "heatMapPoints")
        }
        
        if let regionData = try? encoder.encode(exploredRegions) {
            UserDefaults.standard.set(regionData, forKey: "exploredRegions")
        }
        
        if let poiData = try? encoder.encode(pointsOfInterest) {
            UserDefaults.standard.set(poiData, forKey: "pointsOfInterest")
        }
        
        UserDefaults.standard.set(totalExploredArea, forKey: "totalExploredArea")
        
        let cellArray = Array(visitedCells)
        UserDefaults.standard.set(cellArray, forKey: "visitedCells")
    }
    
    private func loadData() {
        let decoder = JSONDecoder()
        
        if let heatData = UserDefaults.standard.data(forKey: "heatMapPoints"),
           let points = try? decoder.decode([HeatMapPoint].self, from: heatData) {
            heatMapPoints = points
        }
        
        if let regionData = UserDefaults.standard.data(forKey: "exploredRegions"),
           let regions = try? decoder.decode([ExploredRegion].self, from: regionData) {
            exploredRegions = regions
        }
        
        if let poiData = UserDefaults.standard.data(forKey: "pointsOfInterest"),
           let pois = try? decoder.decode([PointOfInterest].self, from: poiData) {
            pointsOfInterest = pois
        }
        
        totalExploredArea = UserDefaults.standard.double(forKey: "totalExploredArea")
        
        if let cellArray = UserDefaults.standard.array(forKey: "visitedCells") as? [String] {
            visitedCells = Set(cellArray)
        }
    }
    
    func resetExploration() {
        exploredRegions.removeAll()
        heatMapPoints.removeAll()
        visitedCells.removeAll()
        totalExploredArea = 0
        
        // Reset POI visits
        for i in pointsOfInterest.indices {
            pointsOfInterest[i].isVisited = false
            pointsOfInterest[i].visitCount = 0
            pointsOfInterest[i].lastVisited = nil
        }
        
        saveData()
    }
}

// MARK: - Heat Map Overlay View
struct HeatMapOverlay: View {
    @Bindable var heatMapManager: HeatMapManager
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                for point in heatMapManager.heatMapPoints {
                    let intensity = min(Double(point.intensity) / 10.0, 1.0)
                    let radius = 20 + (intensity * 30)
                    
                    // This would need to be converted to screen coordinates
                    // For now, this is a placeholder
                    let gradient = RadialGradient(
                        colors: [
                            Color.red.opacity(intensity * 0.7),
                            Color.orange.opacity(intensity * 0.5),
                            Color.yellow.opacity(intensity * 0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: radius
                    )
                }
            }
        }
    }
}
