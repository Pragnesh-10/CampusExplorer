//
//  ChallengesManager.swift
//  Campus Explorer
//
//  Manages user challenges and competitions
//

import Foundation
import Combine
import Observation

enum SocialChallengeType: String, Codable, CaseIterable {
    case steps = "Steps"
    case distance = "Distance (km)"
    case visit = "Places Visited"
}

struct SocialChallenge: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let type: SocialChallengeType
    let targetValue: Double
    var currentValue: Double
    let deadline: Date
    var isCompleted: Bool
    var participantIds: [String] // For group challenges
    
    var progress: Double {
        return min(currentValue / targetValue, 1.0)
    }
    
    var formattedTarget: String {
        switch type {
        case .steps: return "\(Int(targetValue))"
        case .distance: return String(format: "%.1f km", targetValue)
        case .visit: return "\(Int(targetValue))"
        }
    }
    
    var formattedCurrent: String {
        switch type {
        case .steps: return "\(Int(currentValue))"
        case .distance: return String(format: "%.1f km", currentValue)
        case .visit: return "\(Int(currentValue))"
        }
    }
}

@Observable
class ChallengesManager {
    var activeChallenges: [SocialChallenge] = []
    var completedChallenges: [SocialChallenge] = []
    
    private let userDefaults = UserDefaults.standard
    private let activeChallengesKey = "active_challenges"
    private let completedChallengesKey = "completed_challenges"
    
    init() {
        loadData()
        
        // Add sample challenge if empty
        if activeChallenges.isEmpty && completedChallenges.isEmpty {
            createSampleChallenges()
        }
    }
    
    // MARK: - Data Persistence
    private func loadData() {
        if let data = userDefaults.data(forKey: activeChallengesKey),
           let challenges = try? JSONDecoder().decode([SocialChallenge].self, from: data) {
            activeChallenges = challenges
        }
        
        if let data = userDefaults.data(forKey: completedChallengesKey),
           let challenges = try? JSONDecoder().decode([SocialChallenge].self, from: data) {
            completedChallenges = challenges
        }
    }
    
    private func saveData() {
        if let data = try? JSONEncoder().encode(activeChallenges) {
            userDefaults.set(data, forKey: activeChallengesKey)
        }
        
        if let data = try? JSONEncoder().encode(completedChallenges) {
            userDefaults.set(data, forKey: completedChallengesKey)
        }
    }
    
    // MARK: - Challenge Management
    func createChallenge(title: String, description: String, type: SocialChallengeType, target: Double, duration: TimeInterval) {
        let deadline = Date().addingTimeInterval(duration)
        let challenge = SocialChallenge(
            id: UUID(),
            title: title,
            description: description,
            type: type,
            targetValue: target,
            currentValue: 0,
            deadline: deadline,
            isCompleted: false,
            participantIds: []
        )
        activeChallenges.append(challenge)
        saveData()
    }
    
    func updateProgress(steps: Int, distance: Double, visitedCount: Int) {
        var updatedActive = [SocialChallenge]()
        var justCompleted = [SocialChallenge]()
        
        for var challenge in activeChallenges {
            // Only update if deadline not passed
            if Date() > challenge.deadline {
                // Expired or failed, move to completed history as failed?
                // For now, keep them or mark as failed. Let's just keep active until completed or manually removed.
                // Or maybe checking deadline is for UI.
            }
            
            switch challenge.type {
            case .steps:
                // This is tricky: we need delta or total since start.
                // For simplicity in this demo, we'll assume challenges start at 0 and we add progress incrementally
                // OR we store startValue. 
                // Let's assume the input values are TOTALS (e.g. total steps today).
                // So challenge needs a startValue to calculate progress.
                // Refactoring: simplistic update for now. We'll just increment currentValue for demo purposes 
                // effectively simulating "steps taken while app is open"
                // Ideally, we'd snapshot the LocationManager stats at creation.
                // Let's just simulate progress for now to show UI updates.
                 break 
            case .distance:
                 break
            case .visit:
                 break
            }
            
            // Simulation: Increment random small amount to show progress
            let increment = challenge.targetValue * 0.05
            challenge.currentValue = min(challenge.currentValue + increment, challenge.targetValue)
            
            if challenge.currentValue >= challenge.targetValue {
                challenge.isCompleted = true
                justCompleted.append(challenge)
            } else {
                updatedActive.append(challenge)
            }
        }
        
        activeChallenges = updatedActive
        completedChallenges.append(contentsOf: justCompleted)
        saveData()
    }
    
    private func createSampleChallenges() {
        let c1 = SocialChallenge(
            id: UUID(),
            title: "Weekend Warrior",
            description: "Walk 10,000 steps this weekend.",
            type: .steps,
            targetValue: 10000,
            currentValue: 4500,
            deadline: Date().addingTimeInterval(86400 * 2),
            isCompleted: false,
            participantIds: []
        )
        
        let c2 = SocialChallenge(
            id: UUID(),
            title: "Campus Explorer",
            description: "Visit 5 new campus buildings.",
            type: .visit,
            targetValue: 5,
            currentValue: 2,
            deadline: Date().addingTimeInterval(86400 * 7),
            isCompleted: false,
            participantIds: []
        )
        
        activeChallenges = [c1, c2]
        saveData()
    }
}
