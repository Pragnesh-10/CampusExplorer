//
//  Models.swift
//  Campus Explorer
//
//  User and Friend models
//

import Foundation
import CoreLocation

struct UserProfile: Codable, Identifiable {
    let id: String
    var username: String
    var email: String
    var friendIds: [String]
    
    init(id: String = UUID().uuidString, username: String, email: String, friendIds: [String] = []) {
        self.id = id
        self.username = username
        self.email = email
        self.friendIds = friendIds
    }
}

struct Friend: Identifiable {
    let id: String
    let username: String
    var currentLocation: CLLocationCoordinate2D?
    var isActive: Bool
}
