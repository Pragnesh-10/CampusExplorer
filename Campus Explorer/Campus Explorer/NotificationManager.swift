//
//  NotificationManager.swift
//  Campus Explorer
//
//  Manages local notifications for achievements, challenges, and reminders
//

import SwiftUI
import UserNotifications
import Observation

@Observable
@MainActor
class NotificationManager {
    static let shared = NotificationManager()
    
    var notificationsEnabled: Bool = false
    var achievementNotifications: Bool = true
    var challengeNotifications: Bool = true
    var reminderNotifications: Bool = true
    var friendNotifications: Bool = true
    var dailyReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    
    private init() {
        loadSettings()
        checkNotificationStatus()
    }
    
    // MARK: - Permission
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.notificationsEnabled = granted
                self.saveSettings()
            }
        }
    }
    
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Achievement Notifications
    func sendAchievementNotification(title: String, body: String) {
        guard notificationsEnabled && achievementNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🏆 Achievement Unlocked!"
        content.subtitle = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Challenge Notifications
    func sendChallengeNotification(title: String, body: String) {
        guard notificationsEnabled && challengeNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "⚡ Challenge Update"
        content.subtitle = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func sendChallengeExpiringNotification(challengeName: String, timeLeft: String) {
        guard notificationsEnabled && challengeNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "⏰ Challenge Expiring Soon!"
        content.body = "\(challengeName) expires in \(timeLeft). Complete it now!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Streak Notifications
    func sendStreakReminderNotification(currentStreak: Int) {
        guard notificationsEnabled && reminderNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🔥 Don't Break Your Streak!"
        content.body = "You have a \(currentStreak)-day streak. Go for a walk today to keep it going!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func sendStreakLostNotification(previousStreak: Int) {
        guard notificationsEnabled && reminderNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "😢 Streak Lost"
        content.body = "Your \(previousStreak)-day streak ended. Start a new one today!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Friend Notifications
    func sendFriendNearbyNotification(friendName: String, distance: Int) {
        guard notificationsEnabled && friendNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "👋 Friend Nearby!"
        content.body = "\(friendName) is \(distance)m away from you"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "friend-\(friendName)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func sendGroupWalkInviteNotification(walkName: String, inviterName: String) {
        guard notificationsEnabled && friendNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🚶‍♂️ Group Walk Invite"
        content.body = "\(inviterName) invited you to join '\(walkName)'"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Daily Reminder
    func scheduleDailyReminder() {
        guard notificationsEnabled && reminderNotifications else { return }
        
        // Remove existing daily reminder
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-reminder"])
        
        let content = UNMutableNotificationContent()
        content.title = "🌅 Good Morning!"
        content.body = "Ready to explore the campus today? Check your challenges!"
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: dailyReminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: "daily-reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-reminder"])
    }
    
    // MARK: - Goal Notifications
    func sendGoalCompletedNotification(goalType: String) {
        guard notificationsEnabled && achievementNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🎯 Goal Completed!"
        content.body = "You've reached your \(goalType) goal for today!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func sendGoalProgressNotification(goalType: String, percentage: Int) {
        guard notificationsEnabled && reminderNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "📊 Progress Update"
        content.body = "You're \(percentage)% towards your \(goalType) goal!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Milestone Notifications
    func sendMilestoneNotification(milestone: String, value: String) {
        guard notificationsEnabled && achievementNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🎉 Milestone Reached!"
        content.body = "You've hit \(value) \(milestone)! Keep it up!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Clear All Notifications
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Persistence
    private func saveSettings() {
        UserDefaults.standard.set(achievementNotifications, forKey: "achievementNotifications")
        UserDefaults.standard.set(challengeNotifications, forKey: "challengeNotifications")
        UserDefaults.standard.set(reminderNotifications, forKey: "reminderNotifications")
        UserDefaults.standard.set(friendNotifications, forKey: "friendNotifications")
        UserDefaults.standard.set(dailyReminderTime.timeIntervalSince1970, forKey: "dailyReminderTime")
    }
    
    private func loadSettings() {
        achievementNotifications = UserDefaults.standard.object(forKey: "achievementNotifications") as? Bool ?? true
        challengeNotifications = UserDefaults.standard.object(forKey: "challengeNotifications") as? Bool ?? true
        reminderNotifications = UserDefaults.standard.object(forKey: "reminderNotifications") as? Bool ?? true
        friendNotifications = UserDefaults.standard.object(forKey: "friendNotifications") as? Bool ?? true
        
        if let timeInterval = UserDefaults.standard.object(forKey: "dailyReminderTime") as? TimeInterval {
            dailyReminderTime = Date(timeIntervalSince1970: timeInterval)
        }
    }
}

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @Bindable var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    if notificationManager.notificationsEnabled {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Notifications Enabled")
                        }
                    } else {
                        Button {
                            notificationManager.requestPermission()
                        } label: {
                            HStack {
                                Image(systemName: "bell.badge")
                                    .foregroundStyle(.blue)
                                Text("Enable Notifications")
                            }
                        }
                    }
                }
                
                Section("Notification Types") {
                    Toggle(isOn: $notificationManager.achievementNotifications) {
                        Label("Achievements & Milestones", systemImage: "trophy.fill")
                    }
                    
                    Toggle(isOn: $notificationManager.challengeNotifications) {
                        Label("Challenge Updates", systemImage: "flag.fill")
                    }
                    
                    Toggle(isOn: $notificationManager.reminderNotifications) {
                        Label("Reminders & Streaks", systemImage: "clock.fill")
                    }
                    
                    Toggle(isOn: $notificationManager.friendNotifications) {
                        Label("Friend Activity", systemImage: "person.2.fill")
                    }
                }
                .disabled(!notificationManager.notificationsEnabled)
                
                Section("Daily Reminder") {
                    Toggle("Enable Daily Reminder", isOn: $notificationManager.reminderNotifications)
                    
                    if notificationManager.reminderNotifications {
                        DatePicker(
                            "Reminder Time",
                            selection: $notificationManager.dailyReminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        
                        Button("Schedule Reminder") {
                            notificationManager.scheduleDailyReminder()
                        }
                    }
                }
                .disabled(!notificationManager.notificationsEnabled)
                
                Section {
                    Button("Clear All Notifications", role: .destructive) {
                        notificationManager.clearAllNotifications()
                    }
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NotificationSettingsView()
}
