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
    
    // Security: Rate limiting
    private var connectionAttempts: [Date] = []
    private let maxAttemptsPerMinute = 5
    
    private let serviceName = "com.campusexplorer.auth"
    private let userAccountKey = "currentUser"
    private let allUsersKey = "allUsers" // Can remain in UserDefaults for mock db
    
    init() {
        loadOrCreateUser()
    }
    
    func generateUserCode() -> String {
        // Generate an 8-character alphanumeric code (stronger security)
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Excluding confusing chars: 0,O,1,I
        let code = String((0..<8).map { _ in characters.randomElement()! })
        return code
    }
    
    func loadOrCreateUser() {
        // Try Keychain first (Secure)
        if let user = KeychainHelper.standard.read(service: serviceName, account: userAccountKey, type: UserProfile.self) {
            currentUser = user
            userCode = user.id
            isAuthenticated = true
        } else if let data = UserDefaults.standard.data(forKey: "currentUser"),
                  let user = try? JSONDecoder().decode(UserProfile.self, from: data) {
            // Migration: Found in UserDefaults, move to Keychain
            KeychainHelper.standard.save(user, service: serviceName, account: userAccountKey)
            UserDefaults.standard.removeObject(forKey: "currentUser")
            
            currentUser = user
            userCode = user.id
            isAuthenticated = true
        } else {
            // Create new user with random code
            let code = generateUserCode()
            let newUser = UserProfile(id: code, username: "Explorer\(String(code.suffix(4)))", email: "", friendIds: [])
            currentUser = newUser
            userCode = code
            isAuthenticated = true
            
            // Save to all users
            var users = loadAllUsers()
            users.append(newUser)
            saveAllUsers(users)
            
            // Secure Save
            saveCurrentUser()
        }
    }
    
    func connectWithFriend(friendCode: String) -> Bool {
        // Rate Limiting Check
        let now = Date()
        connectionAttempts = connectionAttempts.filter { now.timeIntervalSince($0) < 60 }
        
        guard connectionAttempts.count < maxAttemptsPerMinute else {
            print("Security Alert: Rate limit exceeded for friend connection.")
            return false
        }
        
        connectionAttempts.append(now)
        
        guard var user = currentUser else { return false }
        
        // Input sanitization and validation
        let sanitizedCode = friendCode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard sanitizedCode != userCode else { return false } // Can't add yourself
        guard sanitizedCode.count == 8 else { return false } // Must be 8 characters
        
        // Validate alphanumeric only (security: prevent injection)
        // Validate alphanumeric (A-Z, 0-9)
        let allowedCharacters = CharacterSet.alphanumerics
        guard sanitizedCode.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else { return false }
        
        var users = loadAllUsers()
        
        // Check if friend code already exists
        if let _ = users.first(where: { $0.id == sanitizedCode }) {
            // Friend already in database, just connect
            if !user.friendIds.contains(sanitizedCode) {
                user.friendIds.append(sanitizedCode)
                currentUser = user
                updateUserInDatabase(user)
                return true
            }
            return false // Already connected
        } else {
            // Friend code doesn't exist locally - create a placeholder for them
            // This allows connecting with friends on other devices
            let friendUser = UserProfile(
                id: sanitizedCode,
                username: "Explorer\(String(sanitizedCode.suffix(4)))",
                email: "",
                friendIds: []
            )
            users.append(friendUser)
            saveAllUsers(users)
            
            // Now connect
            user.friendIds.append(sanitizedCode)
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
        KeychainHelper.standard.delete(service: serviceName, account: userAccountKey)
        currentUser = nil
        isAuthenticated = false
        loadOrCreateUser()
    }
    
    // MARK: - Private Methods
    
    private func saveCurrentUser() {
        guard let user = currentUser else { return }
        // Save to Keychain
        KeychainHelper.standard.save(user, service: serviceName, account: userAccountKey)
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
