//
//  SocialView.swift
//  Campus Explorer
//
//  Hub for social features: Chats, Friends, and Events
//

import SwiftUI

struct SocialView: View {
    @Bindable var chatManager: ChatManager
    @EnvironmentObject var authManager: AuthManager
    @Bindable var challengesManager: ChallengesManager
    @Bindable var eventsManager: EventsManager
    
    @State private var selectedTab: SocialTab = .chats
    
    enum SocialTab: String, CaseIterable {
        case chats = "Chats"
        case friends = "Friends"
        case challenges = "Challenges"
        case events = "Events"
        
        var icon: String {
            switch self {
            case .chats: return "bubble.left.and.bubble.right.fill"
            case .friends: return "person.2.fill"
            case .challenges: return "flag.checkered"
            case .events: return "calendar.badge.clock"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // segmented control
            Picker("Social Tab", selection: $selectedTab) {
                ForEach(SocialTab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color(.systemBackground))
            
            // Content
            TabView(selection: $selectedTab) {
                ChatView(chatManager: chatManager)
                    .tag(SocialTab.chats)
                
                FriendsView()
                    .environmentObject(authManager)
                    .tag(SocialTab.friends)
                
                ChallengesView(challengesManager: challengesManager)
                    .tag(SocialTab.challenges)
                
                EventsView(eventsManager: eventsManager)
                    .tag(SocialTab.events)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("Social")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SocialView(
            chatManager: ChatManager(),
            challengesManager: ChallengesManager(),
            eventsManager: EventsManager()
        )
            .environmentObject(AuthManager())
    }
}
