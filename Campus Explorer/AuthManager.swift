//
//  AuthManager.swift
//  Campus Explorer
//
//  Simple code-based connection manager
//

import Foundation
import Combine

class AuthManager: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var isAuthenticated = false
    @Published var userCode: String = ""
    
    private let userDefaultsKey = "currentUser"
    private let allUsersKey = "allUsers"
    
    init() {
        loadOrCreateUser()
    }
    
    func generateUserCode() -> String {
        // Generate a 6-digit random code
        let code = String(format: "%06d", Int.random(in: 100000...999999))
        return code
    }
    
    func loadOrCreateUser() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(UserProfile.self, from: data) {
            currentUser = user
            userCode = user.id
            isAuthenticated = true
        } else {
            // Create new user with random code
            let code = generateUserCode()
            let newUser = UserProfile(id: code, username: "Explorer\(String(code.suffix(4)))", email: "", password: "", friendIds: [])
            currentUser = newUser
            userCode = code
            isAuthenticated = true
            
            // Save to all users
            var users = loadAllUsers()
            users.append(newUser)
            saveAllUsers(users)
            saveCurrentUser()
        }
    }
    
    func connectWithFriend(friendCode: String) -> Bool {
        guard var user = currentUser else { return false }
        guard friendCode != userCode else { return false } // Can't add yourself
        guard friendCode.count == 6 else { return false } // Must be 6 digits
        
        var users = loadAllUsers()
        
        // Check if friend code already exists
        if let _ = users.first(where: { $0.id == friendCode }) {
            // Friend already in database, just connect
            if !user.friendIds.contains(friendCode) {
                user.friendIds.append(friendCode)
                currentUser = user
                updateUserInDatabase(user)
                return true
            }
            return false // Already connected
        } else {
            // Friend code doesn't exist locally - create a placeholder for them
            // This allows connecting with friends on other devices
            let friendUser = UserProfile(
                id: friendCode,
                username: "Explorer\(String(friendCode.suffix(4)))",
                email: "",
                password: "",
                friendIds: []
            )
            users.append(friendUser)
            saveAllUsers(users)
            
            // Now connect
            user.friendIds.append(friendCode)
            currentUser = user
            updateUserInDatabase(user)
            return true
        }
    }
    
    func removeFriend(friendId: String) {
        guard var user = currentUser else { return }
        user.friendIds.removeAll { $0 == friendId }
        currentUser = user
        updateUserInDatabase(user)
    }
    
    func getFriends() -> [UserProfile] {
        guard let user = currentUser else { return [] }
        let users = loadAllUsers()
        return users.filter { user.friendIds.contains($0.id) }
    }
    
    func resetAccount() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        currentUser = nil
        isAuthenticated = false
        loadOrCreateUser()
    }
    
    // MARK: - Private Methods
    
    private func saveCurrentUser() {
        if let user = currentUser,
           let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    private func loadAllUsers() -> [UserProfile] {
        if let data = UserDefaults.standard.data(forKey: allUsersKey),
           let users = try? JSONDecoder().decode([UserProfile].self, from: data) {
            return users
        }
        return []
    }
    
    private func saveAllUsers(_ users: [UserProfile]) {
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: allUsersKey)
        }
    }
    
    private func updateUserInDatabase(_ user: UserProfile) {
        var users = loadAllUsers()
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = user
        }
        saveAllUsers(users)
        saveCurrentUser()
    }
}
