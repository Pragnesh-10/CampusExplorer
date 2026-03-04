//
//  LeaderboardManager.swift
//  Campus Explorer
//
//  Leaderboards and competitive rankings
//

import SwiftUI
import Observation

// MARK: - Leaderboard Models
struct LeaderboardEntry: Identifiable, Codable {
    let id: String
    var username: String
    var avatarEmoji: String
    var steps: Int
    var distance: Double // meters
    var calories: Double
    var explorationPercentage: Double
    var achievementsCount: Int
    var streakDays: Int
    var totalPoints: Int
    var lastUpdated: Date
    
    var rank: Int = 0
}

enum LeaderboardType: String, CaseIterable {
    case steps = "Steps"
    case distance = "Distance"
    case calories = "Calories"
    case exploration = "Exploration"
    case achievements = "Achievements"
    case streak = "Streak"
    case points = "Points"
    
    var iconName: String {
        switch self {
        case .steps: return "figure.walk"
        case .distance: return "map"
        case .calories: return "flame.fill"
        case .exploration: return "globe"
        case .achievements: return "trophy.fill"
        case .streak: return "flame"
        case .points: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .steps: return .blue
        case .distance: return .green
        case .calories: return .orange
        case .exploration: return .purple
        case .achievements: return .yellow
        case .streak: return .red
        case .points: return .indigo
        }
    }
    
    var unit: String {
        switch self {
        case .steps: return "steps"
        case .distance: return "km"
        case .calories: return "cal"
        case .exploration: return "%"
        case .achievements: return ""
        case .streak: return "days"
        case .points: return "pts"
        }
    }
}

enum LeaderboardPeriod: String, CaseIterable {
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
    case allTime = "All Time"
}

// MARK: - Leaderboard Manager
@Observable
@MainActor
class LeaderboardManager {
    var entries: [LeaderboardEntry] = []
    var currentUserEntry: LeaderboardEntry?
    var selectedType: LeaderboardType = .steps
    var selectedPeriod: LeaderboardPeriod = .week
    var isLoading: Bool = false
    var friendsOnly: Bool = false
    
    private let avatarEmojis = ["🧑‍🎓", "👩‍🎓", "👨‍🎓", "🧑‍💻", "👩‍💻", "👨‍💻", "🏃", "🏃‍♀️", "🚶", "🚶‍♀️", "🧗", "🏋️", "🤸", "🧘", "⛹️", "🚴"]
    
    init() {
        loadLeaderboard()
    }
    
    var sortedEntries: [LeaderboardEntry] {
        var sorted = entries.sorted { entry1, entry2 in
            switch selectedType {
            case .steps: return entry1.steps > entry2.steps
            case .distance: return entry1.distance > entry2.distance
            case .calories: return entry1.calories > entry2.calories
            case .exploration: return entry1.explorationPercentage > entry2.explorationPercentage
            case .achievements: return entry1.achievementsCount > entry2.achievementsCount
            case .streak: return entry1.streakDays > entry2.streakDays
            case .points: return entry1.totalPoints > entry2.totalPoints
            }
        }
        
        // Assign ranks
        for i in 0..<sorted.count {
            sorted[i].rank = i + 1
        }
        
        if friendsOnly {
            // Filter to only friends (simulated - in real app would use actual friend list)
            sorted = sorted.filter { $0.id.contains("friend") || $0.id == currentUserEntry?.id }
        }
        
        return sorted
    }
    
    var currentUserRank: Int {
        guard let userId = currentUserEntry?.id else { return 0 }
        return sortedEntries.firstIndex { $0.id == userId }.map { $0 + 1 } ?? 0
    }
    
    func getValue(for entry: LeaderboardEntry) -> String {
        switch selectedType {
        case .steps: return "\(entry.steps.formatted())"
        case .distance: return String(format: "%.1f", entry.distance / 1000)
        case .calories: return String(format: "%.0f", entry.calories)
        case .exploration: return String(format: "%.1f", entry.explorationPercentage)
        case .achievements: return "\(entry.achievementsCount)"
        case .streak: return "\(entry.streakDays)"
        case .points: return "\(entry.totalPoints.formatted())"
        }
    }
    
    // MARK: - Update Current User Stats
    func updateCurrentUser(steps: Int, distance: Double, calories: Double, exploration: Double, achievements: Int, streak: Int, points: Int, username: String) {
        if var entry = currentUserEntry {
            entry.steps = steps
            entry.distance = distance
            entry.calories = calories
            entry.explorationPercentage = exploration
            entry.achievementsCount = achievements
            entry.streakDays = streak
            entry.totalPoints = points
            entry.username = username
            entry.lastUpdated = Date()
            currentUserEntry = entry
            
            // Update in entries list
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[index] = entry
            }
        } else {
            // Create new entry
            let newEntry = LeaderboardEntry(
                id: UUID().uuidString,
                username: username,
                avatarEmoji: avatarEmojis.randomElement() ?? "🧑‍🎓",
                steps: steps,
                distance: distance,
                calories: calories,
                explorationPercentage: exploration,
                achievementsCount: achievements,
                streakDays: streak,
                totalPoints: points,
                lastUpdated: Date()
            )
            currentUserEntry = newEntry
            entries.append(newEntry)
        }
        
        saveLeaderboard()
    }
    
    // MARK: - Persistence
    private func saveLeaderboard() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: "leaderboardEntries")
        }
        if let current = currentUserEntry, let encoded = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(encoded, forKey: "currentUserLeaderboardEntry")
        }
    }
    
    private func loadLeaderboard() {
        // Load current user
        if let data = UserDefaults.standard.data(forKey: "currentUserLeaderboardEntry"),
           let entry = try? JSONDecoder().decode(LeaderboardEntry.self, from: data) {
            currentUserEntry = entry
        }
        
        // Load entries or generate sample data
        if let data = UserDefaults.standard.data(forKey: "leaderboardEntries"),
           let loadedEntries = try? JSONDecoder().decode([LeaderboardEntry].self, from: data) {
            entries = loadedEntries
        } else {
            // Generate sample leaderboard data
            generateSampleData()
        }
        
        // Add current user to entries if not present
        if let current = currentUserEntry, !entries.contains(where: { $0.id == current.id }) {
            entries.append(current)
        }
    }
    
    private func generateSampleData() {
        let sampleNames: [(String, String)] = [
            ("Arjun K.", "A"), ("Priya S.", "P"), ("Rahul M.", "R"),
            ("Ananya R.", "A"), ("Vikram P.", "V"), ("Sneha D.", "S"),
            ("Karthik N.", "K"), ("Divya L.", "D"), ("Arun T.", "A"),
            ("Meera J.", "M"), ("Sanjay V.", "S"), ("Lakshmi B.", "L"),
            ("Deepak H.", "D"), ("Kavitha S.", "K"), ("Mohan R.", "M")
        ]
        
        entries = sampleNames.enumerated().map { index, pair in
            let name = pair.0
            let initial = pair.1
            // Generate realistic random data with some variation
            let baseSteps = Int.random(in: 3000...15000)
            let baseDistance = Double.random(in: 2000...12000)
            let baseCalories = Double(baseSteps) * 0.04
            
            return LeaderboardEntry(
                id: "friend-\(index)",
                username: name,
                avatarEmoji: initial,
                steps: baseSteps,
                distance: baseDistance,
                calories: baseCalories,
                explorationPercentage: Double.random(in: 10...85),
                achievementsCount: Int.random(in: 2...15),
                streakDays: Int.random(in: 1...30),
                totalPoints: Int.random(in: 500...5000),
                lastUpdated: Date().addingTimeInterval(-Double.random(in: 0...86400))
            )
        }
    }
    
    func refreshLeaderboard() {
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            // In a real app, this would fetch from a server
            // For now, just slightly randomize existing data
            self?.entries = self?.entries.map { entry in
                var updated = entry
                updated.steps += Int.random(in: -100...500)
                updated.distance += Double.random(in: -50...200)
                updated.calories = Double(updated.steps) * 0.04
                updated.lastUpdated = Date()
                return updated
            } ?? []
            
            self?.isLoading = false
        }
    }
}

// MARK: - Leaderboard View
struct LeaderboardView: View {
    @Bindable var leaderboardManager: LeaderboardManager
    @ObservedObject var locationManager: LocationManager
    @Bindable var achievementsManager: AchievementsManager
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Type Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(LeaderboardType.allCases, id: \.self) { type in
                            Button {
                                leaderboardManager.selectedType = type
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: type.iconName)
                                    Text(type.rawValue)
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(leaderboardManager.selectedType == type ? type.color : Color(.systemGray5))
                                .foregroundStyle(leaderboardManager.selectedType == type ? .white : .primary)
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Period & Friends Filter
                HStack {
                    Picker("Period", selection: $leaderboardManager.selectedPeriod) {
                        ForEach(LeaderboardPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Spacer()
                    
                    Toggle("Friends Only", isOn: $leaderboardManager.friendsOnly)
                        .toggleStyle(.button)
                        .font(.caption)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                Divider()
                
                // Current User Card
                if let current = leaderboardManager.currentUserEntry {
                    CurrentUserRankCard(
                        entry: current,
                        rank: leaderboardManager.currentUserRank,
                        type: leaderboardManager.selectedType,
                        leaderboardManager: leaderboardManager
                    )
                    .padding()
                }
                
                // Leaderboard List
                if leaderboardManager.isLoading {
                    Spacer()
                    ProgressView("Loading...")
                    Spacer()
                } else {
                    List {
                        ForEach(leaderboardManager.sortedEntries) { entry in
                            LeaderboardEntryRow(
                                entry: entry,
                                type: leaderboardManager.selectedType,
                                isCurrentUser: entry.id == leaderboardManager.currentUserEntry?.id,
                                leaderboardManager: leaderboardManager
                            )
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        leaderboardManager.refreshLeaderboard()
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        leaderboardManager.refreshLeaderboard()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                // Update current user stats
                leaderboardManager.updateCurrentUser(
                    steps: locationManager.stepCount,
                    distance: locationManager.totalDistance,
                    calories: locationManager.caloriesBurned,
                    exploration: 0, // Would come from heatMapManager
                    achievements: achievementsManager.unlockedAchievementsCount,
                    streak: achievementsManager.streakData.currentStreak,
                    points: achievementsManager.totalPoints,
                    username: authManager.currentUser?.username ?? "Explorer"
                )
            }
        }
    }
}

// MARK: - Current User Rank Card
struct CurrentUserRankCard: View {
    let entry: LeaderboardEntry
    let rank: Int
    let type: LeaderboardType
    @Bindable var leaderboardManager: LeaderboardManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank Badge
            ZStack {
                Circle()
                    .fill(rankColor.gradient)
                    .frame(width: 50, height: 50)
                
                Text("#\(rank)")
                    .font(.headline)
                    .bold()
                    .foregroundStyle(.white)
            }
            
            // Avatar & Name
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(entry.avatarEmoji)
                        .font(.title2)
                    
                    Text("You")
                        .font(.headline)
                }
                
                Text(entry.username)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Value
            VStack(alignment: .trailing) {
                Text(leaderboardManager.getValue(for: entry))
                    .font(.title2)
                    .bold()
                    .foregroundStyle(type.color)
                
                Text(type.unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(type.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(type.color, lineWidth: 2)
        }
    }
    
    var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
}

// MARK: - Leaderboard Entry Row
struct LeaderboardEntryRow: View {
    let entry: LeaderboardEntry
    let type: LeaderboardType
    let isCurrentUser: Bool
    @Bindable var leaderboardManager: LeaderboardManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            ZStack {
                if entry.rank <= 3 {
                    Circle()
                        .fill(rankColor.gradient)
                        .frame(width: 36, height: 36)
                    
                    if entry.rank == 1 {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.white)
                            .font(.caption)
                    } else {
                        Text("\(entry.rank)")
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(.white)
                    }
                } else {
                    Text("\(entry.rank)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 36)
                }
            }
            
            // Avatar
            Text(entry.avatarEmoji)
                .font(.title2)
            
            // Name
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(entry.username)
                        .font(.subheadline)
                        .fontWeight(isCurrentUser ? .bold : .regular)
                    
                    if isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text(entry.lastUpdated, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Value
            HStack(spacing: 4) {
                Text(leaderboardManager.getValue(for: entry))
                    .font(.headline)
                    .foregroundStyle(type.color)
                
                Text(type.unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(isCurrentUser ? type.color.opacity(0.1) : Color.clear)
    }
    
    var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
}

#Preview {
    LeaderboardView(
        leaderboardManager: LeaderboardManager(),
        locationManager: LocationManager(),
        achievementsManager: AchievementsManager()
    )
    .environmentObject(AuthManager())
}
