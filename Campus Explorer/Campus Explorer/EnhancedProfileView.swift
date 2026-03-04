//
//  EnhancedProfileView.swift
//  Campus Explorer
//
//  User profile with stats and settings
//

import SwiftUI
import MapKit

struct EnhancedProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var locationManager: LocationManager
    @Bindable var achievementsManager: AchievementsManager
    @Bindable var heatMapManager: HeatMapManager
    @Bindable var mapSettings: MapSettingsManager
    
    // Placeholder URL
    let appStoreURL = URL(string: "https://testflight.apple.com/join/placeholder")!
    
    @State private var showNotificationSettings = false
    @State private var showFriends = false
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Header
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.blue.gradient)
                                .frame(width: 70, height: 70)
                            
                            Text(String(authManager.currentUser?.username.prefix(1) ?? "U"))
                                .font(.title)
                                .bold()
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authManager.currentUser?.username ?? "Explorer")
                                .font(.title2)
                                .bold()
                            
                            HStack {
                                Image(systemName: "qrcode")
                                Text(authManager.userCode)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            // Points and Level
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                Text("\(achievementsManager.totalPoints) points")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Quick Stats
                Section("Today's Progress") {
                    HStack {
                        QuickStatRow(icon: "figure.walk", title: "Steps", value: "\(locationManager.stepCount)", goal: "\(achievementsManager.goals.dailySteps)")
                    }
                    HStack {
                        QuickStatRow(icon: "map", title: "Distance", value: String(format: "%.1f km", locationManager.totalDistance / 1000), goal: String(format: "%.1f km", achievementsManager.goals.dailyDistance / 1000))
                    }
                    HStack {
                        QuickStatRow(icon: "flame.fill", title: "Streak", value: "\(achievementsManager.streakData.currentStreak) days", goal: "Best: \(achievementsManager.streakData.longestStreak)")
                    }
                }
                
                // Achievements Summary
                Section("Achievements") {
                    HStack {
                        Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                        Text("Badges Earned")
                        Spacer()
                        Text("\(achievementsManager.unlockedAchievementsCount)/\(achievementsManager.achievements.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "flag.fill")
                        .foregroundStyle(.blue)
                        Text("Challenges Completed")
                        Spacer()
                        Text("\(achievementsManager.challenges.filter { $0.isCompleted }.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.purple)
                        Text("POIs Visited")
                        Spacer()
                        Text("\(heatMapManager.visitedPOIsCount)/\(heatMapManager.pointsOfInterest.count)")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Social
                Section("Social") {
                    NavigationLink {
                        FriendsView()
                            .environmentObject(authManager)
                    } label: {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundStyle(.blue)
                            Text("Friends")
                            Spacer()
                            Text("\(authManager.currentUser?.friendIds.count ?? 0)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    

                    
                    // Share App
                    ShareLink(item: appStoreURL, subject: Text("Join Campus Explorer!"), message: Text("Let's explore campus together! Download: \(appStoreURL.absoluteString)")) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.blue)
                            Text("Share App")
                            Spacer()
                        }
                    }
                }
                
                // Settings
                Section("Settings") {
                    Button {
                        showNotificationSettings = true
                    } label: {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(.red)
                            Text("Notifications")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                    
                    HStack {
                        Image(systemName: "map")
                            .foregroundStyle(.green)
                        Text("Map Style")
                        Spacer()
                        Text(mapSettings.selectedMapStyle.rawValue)
                            .foregroundStyle(.secondary)
                    }
                    
                    NavigationLink(destination: AccessibilitySettingsView()) {
                        HStack {
                            Image(systemName: "accessibility")
                                .foregroundStyle(.primary)
                            Text("Accessibility")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // App Info
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Made with")
                        Spacer()
                        Text("SwiftUI · iOS 17+")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showNotificationSettings) {
                NotificationSettingsView()
            }
        }
    }
}

struct QuickStatRow: View {
    let icon: String
    let title: String
    let value: String
    let goal: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 30)
            Text(title)
            Spacer()
            VStack(alignment: .trailing) {
                Text(value)
                    .bold()
                Text("Goal: \(goal)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// Reusing AccessibilitySettingsView from ProfileView or defining here if ProfileView is removed
struct AccessibilitySettingsView: View {
    @State private var accessibilityManager = AccessibilityManager()
    
    var body: some View {
        Form {
            Section {
                Toggle("High Contrast", isOn: $accessibilityManager.preferHighContrast)
                Toggle("Large Text", isOn: $accessibilityManager.largeTextEnabled)
            } footer: {
               Text("These settings override system defaults for this app.")
            }
        }
        .navigationTitle("Accessibility")
    }
}

#Preview {
    EnhancedProfileView(
        locationManager: LocationManager(),
        achievementsManager: AchievementsManager(),
        heatMapManager: HeatMapManager(),
        mapSettings: MapSettingsManager()
    )
    .environmentObject(AuthManager())
}
