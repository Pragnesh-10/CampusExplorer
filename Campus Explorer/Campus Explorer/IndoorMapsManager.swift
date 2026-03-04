//
//  IndoorMapsManager.swift
//  Campus Explorer
//
//  Indoor maps and building navigation
//

import SwiftUI
import MapKit
import Observation

// MARK: - Building Models
struct Building: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var shortName: String
    var coordinate: CodableCoordinate
    var floors: [Floor]
    var description: String
    var category: BuildingCategory
    var imageURL: String?
    var isOpen: Bool
    var openingHours: String?
    
    var clCoordinate: CLLocationCoordinate2D {
        coordinate.clCoordinate
    }
    
    static func == (lhs: Building, rhs: Building) -> Bool {
        lhs.id == rhs.id
    }
}

struct Floor: Identifiable, Codable {
    let id: String
    var number: Int
    var name: String
    var rooms: [Room]
    var floorPlanImage: String? // Asset name or URL
}

struct Room: Identifiable, Codable {
    let id: String
    var name: String
    var number: String
    var type: RoomType
    var floor: Int
    var description: String?
    var capacity: Int?
    var amenities: [String]
    var relativeX: Double // 0-1 position on floor plan
    var relativeY: Double
    var isFavorite: Bool = false
}

enum RoomType: String, Codable, CaseIterable {
    case classroom = "Classroom"
    case lab = "Laboratory"
    case office = "Office"
    case restroom = "Restroom"
    case elevator = "Elevator"
    case stairs = "Stairs"
    case cafeteria = "Cafeteria"
    case library = "Library"
    case auditorium = "Auditorium"
    case gym = "Gymnasium"
    case common = "Common Area"
    case storage = "Storage"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .classroom: return "book.fill"
        case .lab: return "flask.fill"
        case .office: return "person.crop.square.fill"
        case .restroom: return "toilet.fill"
        case .elevator: return "arrow.up.arrow.down.square.fill"
        case .stairs: return "stairs"
        case .cafeteria: return "fork.knife"
        case .library: return "books.vertical.fill"
        case .auditorium: return "theatermasks.fill"
        case .gym: return "figure.run"
        case .common: return "sofa.fill"
        case .storage: return "archivebox.fill"
        case .other: return "square.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .classroom: return .blue
        case .lab: return .purple
        case .office: return .orange
        case .restroom: return .cyan
        case .elevator: return .gray
        case .stairs: return .gray
        case .cafeteria: return .red
        case .library: return .brown
        case .auditorium: return .pink
        case .gym: return .green
        case .common: return .yellow
        case .storage: return .secondary
        case .other: return .secondary
        }
    }
}

enum BuildingCategory: String, Codable, CaseIterable {
    case academic = "Academic"
    case administrative = "Administrative"
    case residential = "Residential"
    case recreation = "Recreation"
    case dining = "Dining"
    case library = "Library"
    case medical = "Medical"
    case parking = "Parking"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .academic: return "graduationcap.fill"
        case .administrative: return "building.2.fill"
        case .residential: return "house.fill"
        case .recreation: return "figure.run"
        case .dining: return "fork.knife"
        case .library: return "books.vertical.fill"
        case .medical: return "cross.fill"
        case .parking: return "car.fill"
        case .other: return "building.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .academic: return .blue
        case .administrative: return .orange
        case .residential: return .green
        case .recreation: return .purple
        case .dining: return .red
        case .library: return .brown
        case .medical: return .pink
        case .parking: return .gray
        case .other: return .secondary
        }
    }
}

// MARK: - Navigation Route
struct IndoorRoute {
    var startRoom: Room
    var endRoom: Room
    var building: Building
    var steps: [NavigationStep]
    var estimatedTime: TimeInterval // seconds
    var distance: Double // meters
}

struct NavigationStep: Identifiable {
    let id = UUID()
    var instruction: String
    var icon: String
    var floor: Int?
}

// MARK: - Indoor Maps Manager
@Observable
@MainActor
class IndoorMapsManager {
    var buildings: [Building] = []
    var selectedBuilding: Building?
    var selectedFloor: Floor?
    var selectedRoom: Room?
    var searchQuery: String = ""
    var favoriteRooms: [String] = [] // Room IDs
    var recentlyVisited: [String] = [] // Room IDs
    var currentRoute: IndoorRoute?
    
    init() {
        loadBuildings()
        loadFavorites()
        loadRecentlyVisited()
    }
    
    // MARK: - Search
    var searchResults: [Room] {
        guard !searchQuery.isEmpty else { return [] }
        let query = searchQuery.lowercased()
        
        var results: [Room] = []
        for building in buildings {
            for floor in building.floors {
                for room in floor.rooms {
                    if room.name.lowercased().contains(query) ||
                       room.number.lowercased().contains(query) ||
                       room.type.rawValue.lowercased().contains(query) {
                        results.append(room)
                    }
                }
            }
        }
        return results
    }
    
    func findRoom(by id: String) -> (Building, Floor, Room)? {
        for building in buildings {
            for floor in building.floors {
                if let room = floor.rooms.first(where: { $0.id == id }) {
                    return (building, floor, room)
                }
            }
        }
        return nil
    }
    
    func getBuildingForRoom(_ roomId: String) -> Building? {
        for building in buildings {
            for floor in building.floors {
                if floor.rooms.contains(where: { $0.id == roomId }) {
                    return building
                }
            }
        }
        return nil
    }
    
    // MARK: - Navigation
    func calculateRoute(from startRoom: Room, to endRoom: Room, in building: Building) -> IndoorRoute? {
        var steps: [NavigationStep] = []
        
        // Find floors
        guard let startFloor = building.floors.first(where: { $0.rooms.contains(where: { $0.id == startRoom.id }) }),
              let endFloor = building.floors.first(where: { $0.rooms.contains(where: { $0.id == endRoom.id }) }) else {
            return nil
        }
        
        // Start
        steps.append(NavigationStep(
            instruction: "Start at \(startRoom.name) (\(startRoom.number))",
            icon: "location.fill",
            floor: startFloor.number
        ))
        
        // Check if need to change floors
        if startFloor.number != endFloor.number {
            let direction = endFloor.number > startFloor.number ? "up" : "down"
            let floorDiff = abs(endFloor.number - startFloor.number)
            
            steps.append(NavigationStep(
                instruction: "Exit \(startRoom.name) and head to the elevator/stairs",
                icon: "arrow.right",
                floor: startFloor.number
            ))
            
            steps.append(NavigationStep(
                instruction: "Take the elevator/stairs \(direction) \(floorDiff) floor\(floorDiff > 1 ? "s" : "") to Floor \(endFloor.number)",
                icon: direction == "up" ? "arrow.up" : "arrow.down",
                floor: nil
            ))
            
            steps.append(NavigationStep(
                instruction: "Exit on Floor \(endFloor.number)",
                icon: "arrow.right",
                floor: endFloor.number
            ))
        } else {
            steps.append(NavigationStep(
                instruction: "Exit \(startRoom.name)",
                icon: "arrow.right",
                floor: startFloor.number
            ))
        }
        
        // Destination
        steps.append(NavigationStep(
            instruction: "Navigate to \(endRoom.name) (\(endRoom.number))",
            icon: "mappin.and.ellipse",
            floor: endFloor.number
        ))
        
        steps.append(NavigationStep(
            instruction: "Arrive at \(endRoom.name)",
            icon: "checkmark.circle.fill",
            floor: endFloor.number
        ))
        
        // Estimate time (rough: 30 seconds per floor change, 10 seconds per room)
        let floorChanges = abs(endFloor.number - startFloor.number)
        let estimatedTime = Double(floorChanges * 30 + 20)
        let distance = Double(floorChanges * 4 + 10) // rough meters
        
        return IndoorRoute(
            startRoom: startRoom,
            endRoom: endRoom,
            building: building,
            steps: steps,
            estimatedTime: estimatedTime,
            distance: distance
        )
    }
    
    func startNavigation(to room: Room) {
        guard let building = getBuildingForRoom(room.id) else { return }
        
        // For now, create a simple route from "entrance"
        if let firstFloor = building.floors.first,
           let entranceRoom = firstFloor.rooms.first {
            currentRoute = calculateRoute(from: entranceRoom, to: room, in: building)
        }
    }
    
    func stopNavigation() {
        currentRoute = nil
    }
    
    // MARK: - Favorites
    func toggleFavorite(_ roomId: String) {
        if favoriteRooms.contains(roomId) {
            favoriteRooms.removeAll { $0 == roomId }
        } else {
            favoriteRooms.append(roomId)
        }
        saveFavorites()
    }
    
    func isFavorite(_ roomId: String) -> Bool {
        favoriteRooms.contains(roomId)
    }
    
    // MARK: - Recently Visited
    func markAsVisited(_ roomId: String) {
        recentlyVisited.removeAll { $0 == roomId }
        recentlyVisited.insert(roomId, at: 0)
        if recentlyVisited.count > 10 {
            recentlyVisited = Array(recentlyVisited.prefix(10))
        }
        saveRecentlyVisited()
    }
    
    // MARK: - Persistence
    private func saveFavorites() {
        UserDefaults.standard.set(favoriteRooms, forKey: "favoriteRooms")
    }
    
    private func loadFavorites() {
        favoriteRooms = UserDefaults.standard.stringArray(forKey: "favoriteRooms") ?? []
    }
    
    private func saveRecentlyVisited() {
        UserDefaults.standard.set(recentlyVisited, forKey: "recentlyVisitedRooms")
    }
    
    private func loadRecentlyVisited() {
        recentlyVisited = UserDefaults.standard.stringArray(forKey: "recentlyVisitedRooms") ?? []
    }
    
    private func loadBuildings() {
        // Sample campus buildings for SRM University AP
        buildings = [
            Building(
                id: "main-academic",
                name: "Main Academic Block",
                shortName: "MAB",
                coordinate: CodableCoordinate(CLLocationCoordinate2D(latitude: 16.4352, longitude: 80.5106)),
                floors: [
                    Floor(id: "mab-g", number: 0, name: "Ground Floor", rooms: [
                        Room(id: "mab-g-101", name: "Main Entrance", number: "G-101", type: .common, floor: 0, description: "Main building entrance", capacity: nil, amenities: ["Accessibility Ramp"], relativeX: 0.5, relativeY: 0.9),
                        Room(id: "mab-g-102", name: "Reception", number: "G-102", type: .office, floor: 0, description: "Information desk", capacity: 5, amenities: ["Information", "Help Desk"], relativeX: 0.5, relativeY: 0.7),
                        Room(id: "mab-g-103", name: "Lecture Hall A", number: "G-103", type: .auditorium, floor: 0, description: "Large lecture hall", capacity: 200, amenities: ["Projector", "Microphone", "AC"], relativeX: 0.2, relativeY: 0.4),
                        Room(id: "mab-g-104", name: "Restroom", number: "G-104", type: .restroom, floor: 0, description: nil, capacity: nil, amenities: ["Accessible"], relativeX: 0.8, relativeY: 0.3),
                        Room(id: "mab-g-105", name: "Elevator", number: "G-105", type: .elevator, floor: 0, description: nil, capacity: 10, amenities: ["Accessible"], relativeX: 0.9, relativeY: 0.5)
                    ], floorPlanImage: nil),
                    Floor(id: "mab-1", number: 1, name: "First Floor", rooms: [
                        Room(id: "mab-1-101", name: "Classroom 101", number: "1-101", type: .classroom, floor: 1, description: "Standard classroom", capacity: 40, amenities: ["Projector", "Whiteboard", "AC"], relativeX: 0.2, relativeY: 0.3),
                        Room(id: "mab-1-102", name: "Classroom 102", number: "1-102", type: .classroom, floor: 1, description: "Standard classroom", capacity: 40, amenities: ["Projector", "Whiteboard", "AC"], relativeX: 0.4, relativeY: 0.3),
                        Room(id: "mab-1-103", name: "Computer Lab 1", number: "1-103", type: .lab, floor: 1, description: "Computer laboratory", capacity: 30, amenities: ["Computers", "AC", "Projector"], relativeX: 0.6, relativeY: 0.3),
                        Room(id: "mab-1-104", name: "Faculty Office", number: "1-104", type: .office, floor: 1, description: "Faculty offices", capacity: 10, amenities: ["AC"], relativeX: 0.8, relativeY: 0.5),
                        Room(id: "mab-1-105", name: "Restroom", number: "1-105", type: .restroom, floor: 1, description: nil, capacity: nil, amenities: [], relativeX: 0.1, relativeY: 0.7)
                    ], floorPlanImage: nil),
                    Floor(id: "mab-2", number: 2, name: "Second Floor", rooms: [
                        Room(id: "mab-2-201", name: "Classroom 201", number: "2-201", type: .classroom, floor: 2, description: "Standard classroom", capacity: 40, amenities: ["Projector", "Whiteboard", "AC"], relativeX: 0.2, relativeY: 0.3),
                        Room(id: "mab-2-202", name: "Physics Lab", number: "2-202", type: .lab, floor: 2, description: "Physics laboratory", capacity: 25, amenities: ["Lab Equipment", "AC"], relativeX: 0.5, relativeY: 0.3),
                        Room(id: "mab-2-203", name: "Chemistry Lab", number: "2-203", type: .lab, floor: 2, description: "Chemistry laboratory", capacity: 25, amenities: ["Lab Equipment", "AC", "Fume Hood"], relativeX: 0.7, relativeY: 0.4),
                        Room(id: "mab-2-204", name: "Study Room", number: "2-204", type: .common, floor: 2, description: "Quiet study area", capacity: 20, amenities: ["Quiet Zone", "AC"], relativeX: 0.3, relativeY: 0.7)
                    ], floorPlanImage: nil)
                ],
                description: "Main academic building with classrooms, labs, and offices",
                category: .academic,
                imageURL: nil,
                isOpen: true,
                openingHours: "7:00 AM - 9:00 PM"
            ),
            Building(
                id: "library",
                name: "Central Library",
                shortName: "LIB",
                coordinate: CodableCoordinate(CLLocationCoordinate2D(latitude: 16.4348, longitude: 80.5100)),
                floors: [
                    Floor(id: "lib-g", number: 0, name: "Ground Floor", rooms: [
                        Room(id: "lib-g-101", name: "Library Entrance", number: "G-101", type: .common, floor: 0, description: "Main entrance", capacity: nil, amenities: [], relativeX: 0.5, relativeY: 0.9),
                        Room(id: "lib-g-102", name: "Circulation Desk", number: "G-102", type: .office, floor: 0, description: "Book checkout", capacity: 5, amenities: ["Help Desk"], relativeX: 0.5, relativeY: 0.6),
                        Room(id: "lib-g-103", name: "Reference Section", number: "G-103", type: .library, floor: 0, description: "Reference materials", capacity: 50, amenities: ["Quiet Zone", "AC"], relativeX: 0.3, relativeY: 0.4),
                        Room(id: "lib-g-104", name: "Periodicals", number: "G-104", type: .library, floor: 0, description: "Magazines and journals", capacity: 30, amenities: ["Reading Area"], relativeX: 0.7, relativeY: 0.4)
                    ], floorPlanImage: nil),
                    Floor(id: "lib-1", number: 1, name: "First Floor", rooms: [
                        Room(id: "lib-1-101", name: "Reading Hall", number: "1-101", type: .library, floor: 1, description: "Main reading area", capacity: 100, amenities: ["Quiet Zone", "AC", "Power Outlets"], relativeX: 0.5, relativeY: 0.5),
                        Room(id: "lib-1-102", name: "Digital Library", number: "1-102", type: .lab, floor: 1, description: "Computer access", capacity: 40, amenities: ["Computers", "Internet", "AC"], relativeX: 0.2, relativeY: 0.3),
                        Room(id: "lib-1-103", name: "Group Study Room 1", number: "1-103", type: .common, floor: 1, description: "Group study", capacity: 8, amenities: ["Whiteboard", "AC"], relativeX: 0.8, relativeY: 0.3)
                    ], floorPlanImage: nil)
                ],
                description: "Central library with reading halls, digital resources, and study rooms",
                category: .library,
                imageURL: nil,
                isOpen: true,
                openingHours: "8:00 AM - 10:00 PM"
            ),
            Building(
                id: "cafeteria",
                name: "Campus Cafeteria",
                shortName: "CAF",
                coordinate: CodableCoordinate(CLLocationCoordinate2D(latitude: 16.4345, longitude: 80.5108)),
                floors: [
                    Floor(id: "caf-g", number: 0, name: "Ground Floor", rooms: [
                        Room(id: "caf-g-101", name: "Main Dining Hall", number: "G-101", type: .cafeteria, floor: 0, description: "Main eating area", capacity: 300, amenities: ["AC", "Seating"], relativeX: 0.5, relativeY: 0.5),
                        Room(id: "caf-g-102", name: "Food Court", number: "G-102", type: .cafeteria, floor: 0, description: "Multiple food stalls", capacity: 100, amenities: ["Variety Food"], relativeX: 0.3, relativeY: 0.3),
                        Room(id: "caf-g-103", name: "Coffee Shop", number: "G-103", type: .cafeteria, floor: 0, description: "Coffee and snacks", capacity: 30, amenities: ["WiFi", "Seating"], relativeX: 0.7, relativeY: 0.7)
                    ], floorPlanImage: nil)
                ],
                description: "Campus dining facility with multiple food options",
                category: .dining,
                imageURL: nil,
                isOpen: true,
                openingHours: "7:00 AM - 11:00 PM"
            ),
            Building(
                id: "sports-complex",
                name: "Sports Complex",
                shortName: "SPT",
                coordinate: CodableCoordinate(CLLocationCoordinate2D(latitude: 16.4355, longitude: 80.5115)),
                floors: [
                    Floor(id: "spt-g", number: 0, name: "Ground Floor", rooms: [
                        Room(id: "spt-g-101", name: "Gymnasium", number: "G-101", type: .gym, floor: 0, description: "Fitness center", capacity: 50, amenities: ["Equipment", "AC", "Lockers"], relativeX: 0.3, relativeY: 0.4),
                        Room(id: "spt-g-102", name: "Indoor Court", number: "G-102", type: .gym, floor: 0, description: "Basketball/Badminton", capacity: 40, amenities: ["Sports Equipment"], relativeX: 0.7, relativeY: 0.4),
                        Room(id: "spt-g-103", name: "Locker Room", number: "G-103", type: .restroom, floor: 0, description: "Changing rooms", capacity: 30, amenities: ["Showers", "Lockers"], relativeX: 0.5, relativeY: 0.8)
                    ], floorPlanImage: nil)
                ],
                description: "Sports and fitness facilities",
                category: .recreation,
                imageURL: nil,
                isOpen: true,
                openingHours: "6:00 AM - 9:00 PM"
            ),
            Building(
                id: "admin-block",
                name: "Administrative Block",
                shortName: "ADM",
                coordinate: CodableCoordinate(CLLocationCoordinate2D(latitude: 16.4340, longitude: 80.5095)),
                floors: [
                    Floor(id: "adm-g", number: 0, name: "Ground Floor", rooms: [
                        Room(id: "adm-g-101", name: "Main Office", number: "G-101", type: .office, floor: 0, description: "Administrative office", capacity: 20, amenities: ["Help Desk", "AC"], relativeX: 0.5, relativeY: 0.5),
                        Room(id: "adm-g-102", name: "Admissions", number: "G-102", type: .office, floor: 0, description: "Student admissions", capacity: 10, amenities: ["Seating", "AC"], relativeX: 0.3, relativeY: 0.4),
                        Room(id: "adm-g-103", name: "Finance Office", number: "G-103", type: .office, floor: 0, description: "Fee payments", capacity: 8, amenities: ["AC"], relativeX: 0.7, relativeY: 0.4)
                    ], floorPlanImage: nil),
                    Floor(id: "adm-1", number: 1, name: "First Floor", rooms: [
                        Room(id: "adm-1-101", name: "Dean's Office", number: "1-101", type: .office, floor: 1, description: "Dean office", capacity: 5, amenities: ["AC"], relativeX: 0.5, relativeY: 0.3),
                        Room(id: "adm-1-102", name: "Conference Room", number: "1-102", type: .common, floor: 1, description: "Meeting room", capacity: 20, amenities: ["Projector", "AC", "Video Conferencing"], relativeX: 0.3, relativeY: 0.6)
                    ], floorPlanImage: nil)
                ],
                description: "Administrative offices and student services",
                category: .administrative,
                imageURL: nil,
                isOpen: true,
                openingHours: "9:00 AM - 5:00 PM"
            )
        ]
    }
}
