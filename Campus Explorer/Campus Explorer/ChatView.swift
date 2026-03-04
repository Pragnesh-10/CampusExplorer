//
//  ChatView.swift
//  Campus Explorer
//
//  Chat UI with conversation list and message view
//

import SwiftUI

struct ChatView: View {
    @Bindable var chatManager: ChatManager
    @EnvironmentObject var authManager: AuthManager
    
    @State private var selectedFriend: UserProfile?
    @State private var navigationPath = NavigationPath()
    @State private var showingNewChat = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                if chatManager.conversations.isEmpty {
                    ContentUnavailableView(
                        "No Conversations",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Start chatting with your friends!")
                    )
                } else {
                    ForEach(chatManager.conversations) { conversation in
                        NavigationLink(value: conversation) {
                            ConversationRow(conversation: conversation)
                        }
                    }
                }
            }
            .navigationTitle("Chats")
            .navigationDestination(for: Conversation.self) { conversation in
                if let friend = authManager.getFriends().first(where: { $0.id == conversation.id }) {
                    ChatDetailView(chatManager: chatManager, friend: friend)
                } else {
                    Text("Friend not found")
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewChat = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showingNewChat) {
                NewChatSheet(isPresented: $showingNewChat) { friend in
                    if let existing = chatManager.conversations.first(where: { $0.id == friend.id }) {
                        navigationPath.append(existing)
                    } else {
                        let newConv = Conversation(
                            id: friend.id,
                            friendName: friend.username,
                            lastMessage: "",
                            lastMessageTime: Date(),
                            unreadCount: 0
                        )
                        navigationPath.append(newConv)
                    }
                }
            }
        }
    }
}

// MARK: - Conversation Row
struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.gray)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.friendName)
                        .font(.headline)
                    Spacer()
                    Text(conversation.lastMessageTime, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text(conversation.lastMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Chat Detail View
struct ChatDetailView: View {
    @Bindable var chatManager: ChatManager
    let friend: UserProfile
    @EnvironmentObject var authManager: AuthManager
    
    @State private var messageText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        let messages = chatManager.getMessages(for: friend.id)
                        ForEach(messages) { message in
                            MessageBubble(message: message, isCurrentUser: message.senderId == authManager.currentUser?.id)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: chatManager.messages[friend.id]?.count) { _, _ in
                    if let lastId = chatManager.messages[friend.id]?.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    chatManager.markAsRead(friendId: friend.id)
                    if let lastId = chatManager.messages[friend.id]?.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
            
            // Input Area
            HStack(spacing: 12) {
                TextField("Message...", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                
                Button {
                    guard !messageText.isEmpty, let currentUser = authManager.currentUser else { return }
                    chatManager.sendMessage(
                        text: messageText,
                        to: friend.id,
                        friendName: friend.username,
                        currentUserId: currentUser.id
                    )
                    messageText = ""
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(messageText.isEmpty ? .gray : .blue)
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
            .background(Color(.systemBackground))
            .shadow(radius: 1)
        }
        .navigationTitle(friend.username)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 2) {
                Text(message.text)
                    .padding(12)
                    .background(isCurrentUser ? Color.blue : Color(.systemGray5))
                    .foregroundStyle(isCurrentUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if !isCurrentUser { Spacer() }
        }
    }
}

#Preview {
    ChatView(chatManager: ChatManager())
        .environmentObject(AuthManager())
}

struct NewChatSheet: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var isPresented: Bool
    var onSelectFriend: (UserProfile) -> Void
    
    var body: some View {
        NavigationStack {
            List(authManager.getFriends()) { friend in
                Button {
                    onSelectFriend(friend)
                    isPresented = false
                } label: {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        Text(friend.username)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("New Message")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
            .overlay {
                if authManager.getFriends().isEmpty {
                    ContentUnavailableView(
                        "No Friends Yet",
                        systemImage: "person.2.slash",
                        description: Text("Add friends in the Social tab to start chatting!")
                    )
                }
            }
        }
    }
}
