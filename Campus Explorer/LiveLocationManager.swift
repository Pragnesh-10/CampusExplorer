//
//  LiveLocationManager.swift
//  Campus Explorer
//
//  Manages live location sharing with friends
//

import SwiftUI
import CoreLocation
import Observation

// MARK: - Friend Location
struct FriendLocation: Identifiable, Codable {
    let id: UUID
    let friendId: String
    let friendName: String
    let friendCode: String
    var coordinate: CodableCoordinate
    var lastUpdated: Date
    var isActive: Bool
    var status: FriendStatus
    var currentActivity: String
    
    init(friendId: String, friendName: String, friendCode: String, coordinate: CLLocationCoordinate2D) {
        self.id = UUID()
        self.friendId = friendId
        self.friendName = friendName
        self.friendCode = friendCode
        self.coordinate = CodableCoordinate(coordinate)
        self.lastUpdated = Date()
        self.isActive = true
        self.status = .exploring
        self.currentActivity = "Exploring campus"
    }
}

// MARK: - Friend Status
enum FriendStatus: String, Codable {
    case exploring = "Exploring"
    case studying = "Studying"
    case eating = "Eating"
    case exercising = "Exercising"
    case inClass = "In Class"
    case offline = "Offline"
    
    var iconName: String {
        switch self {
        case .exploring: return "figure.walk"
        case .studying: return "book.fill"
        case .eating: return "fork.knife"
        case .exercising: return "figure.run"
        case .inClass: return "graduationcap.fill"
        case .offline: return "moon.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .exploring: return .green
        case .studying: return .blue
        case .eating: return .orange
        case .exercising: return .purple
        case .inClass: return .yellow
        case .offline: return .gray
        }
    }
}

// MARK: - Group Walk
struct GroupWalk: Identifiable, Codable {
    let id: UUID
    let name: String
    let creatorId: String
    var participants: [String]
    var startTime: Date
    var endTime: Date?
    var meetingPoint: CodableCoordinate
    var destination: CodableCoordinate?
    var isActive: Bool
    var totalDistance: Double
    var inviteCode: String
    
    init(name: String, creatorId: String, meetingPoint: CLLocationCoordinate2D) {
        self.id = UUID()
        self.name = name
        self.creatorId = creatorId
        self.participants = [creatorId]
        self.startTime = Date()
        self.endTime = nil
        self.meetingPoint = CodableCoordinate(meetingPoint)
        self.destination = nil
        self.isActive = true
        self.totalDistance = 0
        self.inviteCode = String(format: "%06d", Int.random(in: 100000...999999))
    }
}

// MARK: - Live Location Manager
@Observable
@MainActor
class LiveLocationManager {
    var friendLocations: [FriendLocation] = []
    var activeGroupWalks: [GroupWalk] = []
    var isLocationSharingEnabled: Bool = false
    var myStatus: FriendStatus = .exploring
    var myActivity: String = "Exploring campus"
    
    init() {
        loadData()
        setupSimulatedFriends()
    }
    
    // MARK: - Location Sharing
    func enableLocationSharing() {
        isLocationSharingEnabled = true
        saveData()
    }
    
    func disableLocationSharing() {
        isLocationSharingEnabled = false
        saveData()
    }
    
    func updateMyStatus(_ status: FriendStatus) {
        myStatus = status
        saveData()
    }
    
    func updateMyActivity(_ activity: String) {
        myActivity = activity
        saveData()
    }
    
    // MARK: - Friend Functions
    func addFriend(name: String, code: String, coordinate: CLLocationCoordinate2D) {
        let friend = FriendLocation(
            friendId: UUID().uuidString,
            friendName: name,
            friendCode: code,
            coordinate: coordinate
        )
        friendLocations.append(friend)
        saveData()
    }
    
    func removeFriend(_ friendId: String) {
        friendLocations.removeAll { $0.friendId == friendId }
        saveData()
    }
    
    func updateFriendLocation(_ friendId: String, coordinate: CLLocationCoordinate2D) {
        if let index = friendLocations.firstIndex(where: { $0.friendId == friendId }) {
            friendLocations[index].coordinate = CodableCoordinate(coordinate)
            friendLocations[index].lastUpdated = Date()
        }
    }
    
    func distanceToFriend(_ friendId: String, from currentLocation: CLLocation) -> Double? {
        guard let friend = friendLocations.first(where: { $0.friendId == friendId }) else { return nil }
        let friendLocation = CLLocation(latitude: friend.coordinate.latitude, longitude: friend.coordinate.longitude)
        return currentLocation.distance(from: friendLocation)
    }
    
    // MARK: - Group Walk Functions
    func createGroupWalk(name: String, creatorId: String, meetingPoint: CLLocationCoordinate2D) -> GroupWalk {
        let walk = GroupWalk(name: name, creatorId: creatorId, meetingPoint: meetingPoint)
        activeGroupWalks.append(walk)
        saveData()
        return walk
    }
    
    func joinGroupWalk(inviteCode: String, userId: String) -> Bool {
        if let index = activeGroupWalks.firstIndex(where: { $0.inviteCode == inviteCode && $0.isActive }) {
            if !activeGroupWalks[index].participants.contains(userId) {
                activeGroupWalks[index].participants.append(userId)
                saveData()
                return true
            }
        }
        return false
    }
    
    func leaveGroupWalk(_ walkId: UUID, userId: String) {
        if let index = activeGroupWalks.firstIndex(where: { $0.id == walkId }) {
            activeGroupWalks[index].participants.removeAll { $0 == userId }
            if activeGroupWalks[index].participants.isEmpty {
                activeGroupWalks.remove(at: index)
            }
            saveData()
        }
    }
    
    func endGroupWalk(_ walkId: UUID) {
        if let index = activeGroupWalks.firstIndex(where: { $0.id == walkId }) {
            activeGroupWalks[index].isActive = false
            activeGroupWalks[index].endTime = Date()
            saveData()
        }
    }
    
    // MARK: - Simulated Friends (Demo)
    private func setupSimulatedFriends() {
        guard friendLocations.isEmpty else { return }
        
        // SRM University AP center
        let baseLocation = CLLocationCoordinate2D(latitude: 16.4350, longitude: 80.5104)
        
        let simulatedFriends: [(String, String, FriendStatus, String)] = [
            ("Priya", "123456", .studying, "At the library"),
            ("Rahul", "234567", .exploring, "Walking near sports complex"),
            ("Ananya", "345678", .eating, "At food court"),
            ("Vikram", "456789", .exercising, "At gym"),
            ("Sneha", "567890", .inClass, "Engineering Block")
        ]
        
        for (i, (name, code, status, activity)) in simulatedFriends.enumerated() {
            var friend = FriendLocation(
                friendId: UUID().uuidString,
                friendName: name,
                friendCode: code,
                coordinate: CLLocationCoordinate2D(
                    latitude: baseLocation.latitude + Double.random(in: -0.002...0.002),
                    longitude: baseLocation.longitude + Double.random(in: -0.002...0.002)
                )
            )
            friend.status = status
            friend.currentActivity = activity
            friendLocations.append(friend)
        }
        
        saveData()
    }
    
    private func startUpdates() {
        // Updates are now manual - call simulateFriendMovement when needed
    }
    
    func simulateFriendMovement() {
        for i in friendLocations.indices {
            // Randomly move friends slightly
            let latOffset = Double.random(in: -0.0002...0.0002)
            let lonOffset = Double.random(in: -0.0002...0.0002)
            
            friendLocations[i].coordinate = CodableCoordinate(CLLocationCoordinate2D(
                latitude: friendLocations[i].coordinate.latitude + latOffset,
                longitude: friendLocations[i].coordinate.longitude + lonOffset
            ))
            friendLocations[i].lastUpdated = Date()
            
            // Randomly change status occasionally
            if Int.random(in: 0...10) == 0 {
                friendLocations[i].status = FriendStatus.allCases.randomElement() ?? .exploring
            }
        }
    }
    
    // MARK: - Persistence
    private func saveData() {
        let encoder = JSONEncoder()
        
        if let friendData = try? encoder.encode(friendLocations) {
            UserDefaults.standard.set(friendData, forKey: "friendLocations")
        }
        
        if let walkData = try? encoder.encode(activeGroupWalks) {
            UserDefaults.standard.set(walkData, forKey: "activeGroupWalks")
        }
        
        UserDefaults.standard.set(isLocationSharingEnabled, forKey: "isLocationSharingEnabled")
        UserDefaults.standard.set(myStatus.rawValue, forKey: "myStatus")
        UserDefaults.standard.set(myActivity, forKey: "myActivity")
    }
    
    private func loadData() {
        let decoder = JSONDecoder()
        
        if let friendData = UserDefaults.standard.data(forKey: "friendLocations"),
           let friends = try? decoder.decode([FriendLocation].self, from: friendData) {
            friendLocations = friends
        }
        
        if let walkData = UserDefaults.standard.data(forKey: "activeGroupWalks"),
           let walks = try? decoder.decode([GroupWalk].self, from: walkData) {
            activeGroupWalks = walks
        }
        
        isLocationSharingEnabled = UserDefaults.standard.bool(forKey: "isLocationSharingEnabled")
        
        if let statusRaw = UserDefaults.standard.string(forKey: "myStatus"),
           let status = FriendStatus(rawValue: statusRaw) {
            myStatus = status
        }
        
        myActivity = UserDefaults.standard.string(forKey: "myActivity") ?? "Exploring campus"
    }
}

// Extension for FriendStatus to be iterable
extension FriendStatus: CaseIterable {}
