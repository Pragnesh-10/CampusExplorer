//
//  AchievementsManager.swift
//  Campus Explorer
//
//  Manages achievements, badges, streaks, and goals
//

import Foundation
import SwiftUI
import Observation

// MARK: - Achievement Model
struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let requirement: Int
    let type: AchievementType
    var isUnlocked: Bool = false
    var unlockedDate: Date?
    var progress: Int = 0
    
    enum AchievementType: String, Codable {
        case steps
        case distance
        case streak
        case friends
        case exploration
        case challenges
    }
    
    var progressPercentage: Double {
        min(Double(progress) / Double(requirement), 1.0)
    }
}

// MARK: - Challenge Model
struct Challenge: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let requirement: Int
    let type: ChallengeType
    let rewardPoints: Int
    var progress: Int = 0
    var isCompleted: Bool = false
    var expiresAt: Date
    
    enum ChallengeType: String, Codable {
        case daily
        case weekly
    }
    
    var progressPercentage: Double {
        min(Double(progress) / Double(requirement), 1.0)
    }
    
    var isExpired: Bool {
        Date() > expiresAt
    }
}

// MARK: - Goal Model
struct Goal: Identifiable, Codable {
    let id: String
    var dailySteps: Int
    var dailyDistance: Double // in meters
    var weeklySteps: Int
    var weeklyDistance: Double
}

// MARK: - Streak Model
struct StreakData: Codable {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastActiveDate: Date?
    var streakHistory: [Date] = []
}

// MARK: - Activity Feed Item
struct ActivityFeedItem: Identifiable, Codable {
    let id: String
    let userId: String
    let username: String
    let type: ActivityType
    let title: String
    let description: String
    let timestamp: Date
    
    var iconName: String {
        switch type {
        case .achievement: return "trophy.fill"
        case .challenge: return "flag.fill"
        case .streak: return "flame.fill"
        case .milestone: return "star.fill"
        case .social: return "person.2.fill"
        }
    }
    
    enum ActivityType: String, Codable {
        case achievement
        case challenge
        case streak
        case milestone
        case social
    }
}

// MARK: - Achievements Manager
@Observable
@MainActor
class AchievementsManager {
    var achievements: [Achievement] = []
    var challenges: [Challenge] = []
    var streakData = StreakData()
    var goals = Goal(id: "default", dailySteps: 10000, dailyDistance: 5000, weeklySteps: 70000, weeklyDistance: 35000)
    var totalPoints: Int = 0
    var activityFeed: [ActivityFeedItem] = []
    var todaySteps: Int = 0
    var todayDistance: Double = 0
    var weekSteps: Int = 0
    var weekDistance: Double = 0
    
    private let achievementsKey = "achievements"
    private let challengesKey = "challenges"
    private let streakKey = "streakData"
    private let goalsKey = "goals"
    private let pointsKey = "totalPoints"
    private let activityKey = "activityFeed"
    
    init() {
        setupDefaultAchievements()
        loadData()
        generateDailyChallenges()
        checkStreak()
    }
    
    // MARK: - Default Achievements
    private func setupDefaultAchievements() {
        let defaultAchievements = [
            // Steps achievements
            Achievement(id: "steps_1k", title: "First Steps", description: "Walk 1,000 steps", iconName: "figure.walk", requirement: 1000, type: .steps),
            Achievement(id: "steps_5k", title: "Getting Active", description: "Walk 5,000 steps", iconName: "figure.walk", requirement: 5000, type: .steps),
            Achievement(id: "steps_10k", title: "Step Master", description: "Walk 10,000 steps", iconName: "figure.walk.circle", requirement: 10000, type: .steps),
            Achievement(id: "steps_50k", title: "Marathon Walker", description: "Walk 50,000 steps", iconName: "figure.walk.circle.fill", requirement: 50000, type: .steps),
            Achievement(id: "steps_100k", title: "Century Steps", description: "Walk 100,000 steps", iconName: "star.fill", requirement: 100000, type: .steps),
            
            // Distance achievements
            Achievement(id: "dist_1km", title: "First Kilometer", description: "Walk 1 km total", iconName: "map", requirement: 1000, type: .distance),
            Achievement(id: "dist_5km", title: "Explorer", description: "Walk 5 km total", iconName: "map.fill", requirement: 5000, type: .distance),
            Achievement(id: "dist_10km", title: "Adventurer", description: "Walk 10 km total", iconName: "globe", requirement: 10000, type: .distance),
            Achievement(id: "dist_25km", title: "Pathfinder", description: "Walk 25 km total", iconName: "globe.americas.fill", requirement: 25000, type: .distance),
            Achievement(id: "dist_50km", title: "Trail Blazer", description: "Walk 50 km total", iconName: "trophy.fill", requirement: 50000, type: .distance),
            
            // Streak achievements
            Achievement(id: "streak_3", title: "Three Day Streak", description: "Use app 3 days in a row", iconName: "flame", requirement: 3, type: .streak),
            Achievement(id: "streak_7", title: "Week Warrior", description: "Use app 7 days in a row", iconName: "flame.fill", requirement: 7, type: .streak),
            Achievement(id: "streak_30", title: "Monthly Master", description: "Use app 30 days in a row", iconName: "flame.circle.fill", requirement: 30, type: .streak),
            
            // Friends achievements
            Achievement(id: "friends_1", title: "First Friend", description: "Connect with 1 friend", iconName: "person.2", requirement: 1, type: .friends),
            Achievement(id: "friends_5", title: "Social Butterfly", description: "Connect with 5 friends", iconName: "person.2.fill", requirement: 5, type: .friends),
            Achievement(id: "friends_10", title: "Popular Explorer", description: "Connect with 10 friends", iconName: "person.3.fill", requirement: 10, type: .friends),
            
            // Exploration achievements
            Achievement(id: "explore_10", title: "Curious", description: "Visit 10 unique spots", iconName: "mappin", requirement: 10, type: .exploration),
            Achievement(id: "explore_50", title: "Discoverer", description: "Visit 50 unique spots", iconName: "mappin.circle", requirement: 50, type: .exploration),
            Achievement(id: "explore_100", title: "Campus Expert", description: "Visit 100 unique spots", iconName: "mappin.circle.fill", requirement: 100, type: .exploration),
            
            // Challenge achievements
            Achievement(id: "challenge_1", title: "Challenger", description: "Complete 1 challenge", iconName: "checkmark.seal", requirement: 1, type: .challenges),
            Achievement(id: "challenge_10", title: "Challenge Pro", description: "Complete 10 challenges", iconName: "checkmark.seal.fill", requirement: 10, type: .challenges),
            Achievement(id: "challenge_50", title: "Challenge Legend", description: "Complete 50 challenges", iconName: "crown.fill", requirement: 50, type: .challenges),
        ]
        
        if achievements.isEmpty {
            achievements = defaultAchievements
        }
    }
    
    // MARK: - Challenge Generation
    func generateDailyChallenges() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Remove expired challenges
        challenges.removeAll { $0.isExpired && !$0.isCompleted }
        
        // Check if we already have today's challenges
        let hasTodayChallenge = challenges.contains { challenge in
            challenge.type == .daily && calendar.isDate(challenge.expiresAt, inSameDayAs: today.addingTimeInterval(86400))
        }
        
        if !hasTodayChallenge {
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: today)!
            
            let dailyChallenges = [
                Challenge(id: UUID().uuidString, title: "Daily Walker", description: "Walk 5,000 steps today", iconName: "figure.walk", requirement: 5000, type: .daily, rewardPoints: 50, expiresAt: endOfDay),
                Challenge(id: UUID().uuidString, title: "Distance Goal", description: "Walk 2 km today", iconName: "map", requirement: 2000, type: .daily, rewardPoints: 50, expiresAt: endOfDay),
                Challenge(id: UUID().uuidString, title: "Explorer", description: "Visit 5 new spots today", iconName: "mappin", requirement: 5, type: .daily, rewardPoints: 30, expiresAt: endOfDay),
            ]
            
            challenges.append(contentsOf: dailyChallenges)
        }
        
        // Generate weekly challenge if needed
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let hasWeeklyChallenge = challenges.contains { challenge in
            challenge.type == .weekly && challenge.expiresAt > Date()
        }
        
        if !hasWeeklyChallenge {
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
            
            let weeklyChallenges = [
                Challenge(id: UUID().uuidString, title: "Weekly Marathon", description: "Walk 50,000 steps this week", iconName: "figure.walk.circle", requirement: 50000, type: .weekly, rewardPoints: 200, expiresAt: endOfWeek),
                Challenge(id: UUID().uuidString, title: "Distance Champion", description: "Walk 20 km this week", iconName: "globe", requirement: 20000, type: .weekly, rewardPoints: 200, expiresAt: endOfWeek),
            ]
            
            challenges.append(contentsOf: weeklyChallenges)
        }
        
        saveData()
    }
    
    // MARK: - Update Progress
    func updateProgress(steps: Int, distance: Double, pathPoints: Int, friendCount: Int) {
        todaySteps = steps
        todayDistance = distance
        
        // Update achievements
        for i in achievements.indices {
            switch achievements[i].type {
            case .steps:
                achievements[i].progress = steps
            case .distance:
                achievements[i].progress = Int(distance)
            case .streak:
                achievements[i].progress = streakData.currentStreak
            case .friends:
                achievements[i].progress = friendCount
            case .exploration:
                achievements[i].progress = pathPoints / 10 // Approximate unique spots
            case .challenges:
                achievements[i].progress = challenges.filter { $0.isCompleted }.count
            }
            
            // Check if achievement is newly unlocked
            if !achievements[i].isUnlocked && achievements[i].progress >= achievements[i].requirement {
                achievements[i].isUnlocked = true
                achievements[i].unlockedDate = Date()
                totalPoints += 100
                
                // Add to activity feed
                addActivity(type: .achievement, title: "Achievement Unlocked!", description: "Unlocked '\(achievements[i].title)' badge!")
            }
        }
        
        // Update daily/weekly challenges
        for i in challenges.indices where !challenges[i].isCompleted && !challenges[i].isExpired {
            if challenges[i].type == .daily {
                if challenges[i].description.contains("steps") {
                    challenges[i].progress = steps
                } else if challenges[i].description.contains("km") {
                    challenges[i].progress = Int(distance)
                } else if challenges[i].description.contains("spots") {
                    challenges[i].progress = pathPoints / 10
                }
            } else if challenges[i].type == .weekly {
                // For weekly, use accumulated values
                challenges[i].progress = challenges[i].description.contains("steps") ? steps : Int(distance)
            }
            
            // Check if challenge completed
            if challenges[i].progress >= challenges[i].requirement {
                challenges[i].isCompleted = true
                totalPoints += challenges[i].rewardPoints
                addActivity(type: .challenge, title: "Challenge Completed!", description: "Completed '\(challenges[i].title)' challenge!")
            }
        }
        
        saveData()
    }
    
    // MARK: - Streak Management
    func checkStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastActive = streakData.lastActiveDate {
            let lastActiveDay = calendar.startOfDay(for: lastActive)
            let daysDiff = calendar.dateComponents([.day], from: lastActiveDay, to: today).day ?? 0
            
            if daysDiff == 1 {
                // Consecutive day - increment streak
                streakData.currentStreak += 1
                if streakData.currentStreak > streakData.longestStreak {
                    streakData.longestStreak = streakData.currentStreak
                }
                streakData.streakHistory.append(today)
                addActivity(type: .streak, title: "Streak Extended!", description: "🔥 \(streakData.currentStreak) day streak!")
            } else if daysDiff > 1 {
                // Streak broken
                streakData.currentStreak = 1
                streakData.streakHistory = [today]
            }
            // daysDiff == 0 means same day, don't change anything
        } else {
            // First time
            streakData.currentStreak = 1
            streakData.streakHistory = [today]
        }
        
        streakData.lastActiveDate = today
        saveData()
    }
    
    // MARK: - Goals
    func updateGoals(dailySteps: Int? = nil, dailyDistance: Double? = nil, weeklySteps: Int? = nil, weeklyDistance: Double? = nil) {
        if let steps = dailySteps { goals.dailySteps = steps }
        if let dist = dailyDistance { goals.dailyDistance = dist }
        if let wSteps = weeklySteps { goals.weeklySteps = wSteps }
        if let wDist = weeklyDistance { goals.weeklyDistance = wDist }
        saveData()
    }
    
    var dailyStepsProgress: Double {
        min(Double(todaySteps) / Double(goals.dailySteps), 1.0)
    }
    
    var dailyDistanceProgress: Double {
        min(todayDistance / goals.dailyDistance, 1.0)
    }
    
    // MARK: - Activity Feed
    func addActivity(type: ActivityFeedItem.ActivityType, title: String, description: String, userId: String = "me", username: String = "You") {
        let activity = ActivityFeedItem(
            id: UUID().uuidString,
            userId: userId,
            username: username,
            type: type,
            title: title,
            description: description,
            timestamp: Date()
        )
        activityFeed.insert(activity, at: 0)
        
        // Keep only last 50 activities
        if activityFeed.count > 50 {
            activityFeed = Array(activityFeed.prefix(50))
        }
        saveData()
    }
    
    // MARK: - Persistence
    private func saveData() {
        if let achievementsData = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(achievementsData, forKey: achievementsKey)
        }
        if let challengesData = try? JSONEncoder().encode(challenges) {
            UserDefaults.standard.set(challengesData, forKey: challengesKey)
        }
        if let streakDataEncoded = try? JSONEncoder().encode(streakData) {
            UserDefaults.standard.set(streakDataEncoded, forKey: streakKey)
        }
        if let goalsData = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(goalsData, forKey: goalsKey)
        }
        if let activityData = try? JSONEncoder().encode(activityFeed) {
            UserDefaults.standard.set(activityData, forKey: activityKey)
        }
        UserDefaults.standard.set(totalPoints, forKey: pointsKey)
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: achievementsKey),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = decoded
        }
        if let data = UserDefaults.standard.data(forKey: challengesKey),
           let decoded = try? JSONDecoder().decode([Challenge].self, from: data) {
            challenges = decoded
        }
        if let data = UserDefaults.standard.data(forKey: streakKey),
           let decoded = try? JSONDecoder().decode(StreakData.self, from: data) {
            streakData = decoded
        }
        if let data = UserDefaults.standard.data(forKey: goalsKey),
           let decoded = try? JSONDecoder().decode(Goal.self, from: data) {
            goals = decoded
        }
        if let data = UserDefaults.standard.data(forKey: activityKey),
           let decoded = try? JSONDecoder().decode([ActivityFeedItem].self, from: data) {
            activityFeed = decoded
        }
        totalPoints = UserDefaults.standard.integer(forKey: pointsKey)
    }
    
    // MARK: - Statistics
    var unlockedAchievementsCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }
    
    var completedChallengesCount: Int {
        challenges.filter { $0.isCompleted }.count
    }
}
