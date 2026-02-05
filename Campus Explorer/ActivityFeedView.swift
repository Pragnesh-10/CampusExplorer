//
//  ActivityFeedView.swift
//  Campus Explorer
//
//  Social feed showing friend activities
//

import SwiftUI
import CoreLocation

struct ActivityFeedView: View {
    @Bindable var achievementsManager: AchievementsManager
    @Bindable var liveLocationManager: LiveLocationManager
    
    var body: some View {
        NavigationView {
            List {
                // My Status Section
                Section("My Status") {
                    HStack {
                        Image(systemName: liveLocationManager.myStatus.iconName)
                            .foregroundStyle(liveLocationManager.myStatus.color)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading) {
                            Text(liveLocationManager.myStatus.rawValue)
                                .font(.headline)
                            Text(liveLocationManager.myActivity)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Menu {
                            ForEach(FriendStatus.allCases, id: \.self) { status in
                                Button {
                                    liveLocationManager.updateMyStatus(status)
                                } label: {
                                    Label(status.rawValue, systemImage: status.iconName)
                                }
                            }
                        } label: {
                            Text("Change")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                    
                    // Location sharing toggle
                    Toggle(isOn: Binding(
                        get: { liveLocationManager.isLocationSharingEnabled },
                        set: { newValue in
                            if newValue {
                                liveLocationManager.enableLocationSharing()
                            } else {
                                liveLocationManager.disableLocationSharing()
                            }
                        }
                    )) {
                        Label("Share My Location", systemImage: "location.fill")
                    }
                }
                
                // Friends Activity Section
                Section("Friends Activity") {
                    ForEach(liveLocationManager.friendLocations) { friend in
                        FriendActivityRow(friend: friend)
                    }
                }
                
                // Recent Activity Section
                Section("Recent Updates") {
                    ForEach(achievementsManager.activityFeed.prefix(20)) { item in
                        ActivityFeedRow(item: item)
                    }
                }
            }
            .navigationTitle("Activity")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Refresh feed
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
}

// MARK: - Friend Activity Row
struct FriendActivityRow: View {
    let friend: FriendLocation
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(friend.status.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text(String(friend.friendName.prefix(1)))
                    .font(.title2)
                    .bold()
                    .foregroundStyle(friend.status.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(friend.friendName)
                        .font(.headline)
                    
                    Circle()
                        .fill(friend.isActive ? .green : .gray)
                        .frame(width: 8, height: 8)
                }
                
                HStack {
                    Image(systemName: friend.status.iconName)
                        .font(.caption)
                        .foregroundStyle(friend.status.color)
                    
                    Text(friend.currentActivity)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(timeAgo(from: friend.lastUpdated))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Quick actions
            VStack(spacing: 8) {
                Button {
                    // Navigate to friend on map
                } label: {
                    Image(systemName: "location.circle.fill")
                        .foregroundStyle(.blue)
                }
                
                Button {
                    // Message friend
                } label: {
                    Image(systemName: "message.fill")
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }
}

// MARK: - Activity Feed Row
struct ActivityFeedRow: View {
    let item: ActivityFeedItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.iconName)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .bold()
                
                Text(item.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(timeAgo(from: item.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if item.type == .achievement {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.vertical, 2)
    }
    
    private var iconColor: Color {
        switch item.type {
        case .achievement: return .yellow
        case .challenge: return .blue
        case .milestone: return .green
        case .streak: return .orange
        case .social: return .purple
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }
}

// MARK: - Group Walks View
struct GroupWalksView: View {
    @Bindable var liveLocationManager: LiveLocationManager
    @State private var showingCreateWalk = false
    @State private var showingJoinWalk = false
    @State private var walkName = ""
    @State private var joinCode = ""
    
    var body: some View {
        NavigationView {
            List {
                // Active Walks
                Section("Active Group Walks") {
                    if liveLocationManager.activeGroupWalks.filter({ $0.isActive }).isEmpty {
                        Text("No active walks")
                            .foregroundStyle(.secondary)
                            .italic()
                    } else {
                        ForEach(liveLocationManager.activeGroupWalks.filter { $0.isActive }) { walk in
                            GroupWalkRow(walk: walk, liveLocationManager: liveLocationManager)
                        }
                    }
                }
                
                // Past Walks
                Section("Past Walks") {
                    ForEach(liveLocationManager.activeGroupWalks.filter { !$0.isActive }) { walk in
                        GroupWalkRow(walk: walk, liveLocationManager: liveLocationManager)
                    }
                }
            }
            .navigationTitle("Group Walks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingCreateWalk = true
                        } label: {
                            Label("Create Walk", systemImage: "plus")
                        }
                        
                        Button {
                            showingJoinWalk = true
                        } label: {
                            Label("Join Walk", systemImage: "person.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateWalk) {
                CreateWalkSheet(
                    walkName: $walkName,
                    liveLocationManager: liveLocationManager,
                    isPresented: $showingCreateWalk
                )
            }
            .alert("Join Group Walk", isPresented: $showingJoinWalk) {
                TextField("Invite Code", text: $joinCode)
                #if os(iOS)
                    .keyboardType(.numberPad)
                #endif
                Button("Join") {
                    _ = liveLocationManager.joinGroupWalk(inviteCode: joinCode, userId: "currentUser")
                    joinCode = ""
                }
                Button("Cancel", role: .cancel) {
                    joinCode = ""
                }
            }
        }
    }
}

// MARK: - Group Walk Row
struct GroupWalkRow: View {
    let walk: GroupWalk
    @Bindable var liveLocationManager: LiveLocationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(walk.name)
                    .font(.headline)
                
                Spacer()
                
                if walk.isActive {
                    Text("Active")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.blue)
                Text("\(walk.participants.count) participants")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if walk.isActive {
                    Text("Code: \(walk.inviteCode)")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            
            if walk.isActive {
                HStack {
                    Button("Share Code") {
                        // Share invite code
                        #if os(iOS)
                        UIPasteboard.general.string = walk.inviteCode
                        #endif
                    }
                    .font(.caption)
                    
                    Spacer()
                    
                    Button("End Walk") {
                        liveLocationManager.endGroupWalk(walk.id)
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Create Walk Sheet
struct CreateWalkSheet: View {
    @Binding var walkName: String
    @Bindable var liveLocationManager: LiveLocationManager
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section("Walk Details") {
                    TextField("Walk Name", text: $walkName)
                }
                
                Section {
                    Button("Create Walk") {
                        let walk = liveLocationManager.createGroupWalk(
                            name: walkName,
                            creatorId: "currentUser",
                            meetingPoint: CLLocationCoordinate2D(latitude: 16.4350, longitude: 80.5104)
                        )
                        walkName = ""
                        isPresented = false
                    }
                    .disabled(walkName.isEmpty)
                }
            }
            .navigationTitle("Create Group Walk")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        walkName = ""
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    ActivityFeedView(
        achievementsManager: AchievementsManager(),
        liveLocationManager: LiveLocationManager()
    )
}
