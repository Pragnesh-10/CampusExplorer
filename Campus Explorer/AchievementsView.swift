//
//  AchievementsView.swift
//  Campus Explorer
//
//  Displays achievements, badges, and progress
//

import SwiftUI

struct AchievementsView: View {
    @Bindable var achievementsManager: AchievementsManager
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Points and Streak Header
                HStack(spacing: 20) {
                    // Total Points
                    VStack {
                        Text("\(achievementsManager.totalPoints)")
                            .font(.title)
                            .bold()
                            .foregroundStyle(.yellow)
                        Text("Points")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Current Streak
                    VStack {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            Text("\(achievementsManager.streakData.currentStreak)")
                                .font(.title)
                                .bold()
                        }
                        Text("Day Streak")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Badges Count
                    VStack {
                        Text("\(achievementsManager.unlockedAchievementsCount)/\(achievementsManager.achievements.count)")
                            .font(.title)
                            .bold()
                            .foregroundStyle(.green)
                        Text("Badges")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                
                // Tab Picker
                Picker("", selection: $selectedTab) {
                    Text("Badges").tag(0)
                    Text("Challenges").tag(1)
                    Text("Goals").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Content
                TabView(selection: $selectedTab) {
                    badgesView.tag(0)
                    challengesView.tag(1)
                    goalsView.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Achievements")
        }
    }
    
    // MARK: - Badges View
    private var badgesView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                ForEach(achievementsManager.achievements) { achievement in
                    BadgeCard(achievement: achievement)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Challenges View
    private var challengesView: some View {
        List {
            Section("Daily Challenges") {
                ForEach(achievementsManager.challenges.filter { $0.type == .daily && !$0.isExpired }) { challenge in
                    ChallengeRow(challenge: challenge)
                }
            }
            
            Section("Weekly Challenges") {
                ForEach(achievementsManager.challenges.filter { $0.type == .weekly && !$0.isExpired }) { challenge in
                    ChallengeRow(challenge: challenge)
                }
            }
            
            Section("Completed") {
                ForEach(achievementsManager.challenges.filter { $0.isCompleted }.prefix(10)) { challenge in
                    ChallengeRow(challenge: challenge)
                }
            }
        }
    }
    
    // MARK: - Goals View
    private var goalsView: some View {
        List {
            Section("Daily Goals") {
                GoalProgressRow(
                    title: "Steps",
                    icon: "figure.walk",
                    current: achievementsManager.todaySteps,
                    goal: achievementsManager.goals.dailySteps,
                    unit: "steps",
                    color: .blue
                )
                
                GoalProgressRow(
                    title: "Distance",
                    icon: "map",
                    current: Int(achievementsManager.todayDistance),
                    goal: Int(achievementsManager.goals.dailyDistance),
                    unit: "m",
                    color: .green
                )
            }
            
            Section("Weekly Goals") {
                GoalProgressRow(
                    title: "Steps",
                    icon: "figure.walk.circle",
                    current: achievementsManager.weekSteps,
                    goal: achievementsManager.goals.weeklySteps,
                    unit: "steps",
                    color: .purple
                )
                
                GoalProgressRow(
                    title: "Distance",
                    icon: "globe",
                    current: Int(achievementsManager.weekDistance),
                    goal: Int(achievementsManager.goals.weeklyDistance),
                    unit: "m",
                    color: .orange
                )
            }
            
            Section("Streak") {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("Current Streak")
                    Spacer()
                    Text("\(achievementsManager.streakData.currentStreak) days")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                    Text("Longest Streak")
                    Spacer()
                    Text("\(achievementsManager.streakData.longestStreak) days")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Badge Card
struct BadgeCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.iconName)
                    .font(.title)
                    .foregroundStyle(achievement.isUnlocked ? .yellow : .gray)
            }
            
            Text(achievement.title)
                .font(.caption)
                .bold()
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            if !achievement.isUnlocked {
                ProgressView(value: achievement.progressPercentage)
                    .tint(.blue)
                    .frame(width: 60)
                
                Text("\(achievement.progress)/\(achievement.requirement)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .frame(width: 100, height: 140)
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(achievement.isUnlocked ? 1.0 : 0.7)
    }
}

// MARK: - Challenge Row
struct ChallengeRow: View {
    let challenge: Challenge
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: challenge.iconName)
                    .foregroundStyle(challenge.isCompleted ? .green : .blue)
                
                VStack(alignment: .leading) {
                    Text(challenge.title)
                        .font(.headline)
                    Text(challenge.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if challenge.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Text("+\(challenge.rewardPoints)")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.yellow.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            
            if !challenge.isCompleted {
                ProgressView(value: challenge.progressPercentage)
                    .tint(.blue)
                
                HStack {
                    Text("\(challenge.progress)/\(challenge.requirement)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if !challenge.isExpired {
                        Text(timeRemaining(until: challenge.expiresAt))
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func timeRemaining(until date: Date) -> String {
        let interval = date.timeIntervalSinceNow
        if interval < 3600 {
            return "\(Int(interval / 60))m left"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h left"
        } else {
            return "\(Int(interval / 86400))d left"
        }
    }
}

// MARK: - Goal Progress Row
struct GoalProgressRow: View {
    let title: String
    let icon: String
    let current: Int
    let goal: Int
    let unit: String
    let color: Color
    
    var progress: Double {
        min(Double(current) / Double(goal), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(current)/\(goal) \(unit)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            ProgressView(value: progress)
                .tint(color)
            
            if progress >= 1.0 {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Goal completed!")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AchievementsView(achievementsManager: AchievementsManager())
}
