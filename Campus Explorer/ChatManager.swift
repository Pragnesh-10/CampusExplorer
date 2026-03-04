//
//  ChatManager.swift
//  Campus Explorer
//
//  Manages chat conversations and messages between friends
//

import Foundation
import SwiftUI
import Combine

// MARK: - Models
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let senderId: String
    let text: String
    let timestamp: Date
    var isRead: Bool
    
    init(id: UUID = UUID(), senderId: String, text: String, timestamp: Date = Date(), isRead: Bool = false) {
        self.id = id
        self.senderId = senderId
        self.text = text
        self.timestamp = timestamp
        self.isRead = isRead
    }
}

struct Conversation: Identifiable, Codable, Hashable {
    let id: String // Usually friend's ID
    let friendName: String
    var lastMessage: String
    var lastMessageTime: Date
    var unreadCount: Int
}

// MARK: - Chat Manager
@Observable
class ChatManager {
    // MARK: - Properties
    var conversations: [Conversation] = []
    var messages: [String: [ChatMessage]] = [:] // Key is friendId (conversation ID)
    
    private let userDefaults = UserDefaults.standard
    private let conversationsKey = "saved_conversations"
    private let messagesKey = "saved_messages"
    
    // MARK: - Initialization
    init() {
        loadData()
    }
    
    // MARK: - Data Persistence
    private func loadData() {
        if let data = userDefaults.data(forKey: conversationsKey),
           let savedConversations = try? JSONDecoder().decode([Conversation].self, from: data) {
            conversations = savedConversations
        }
        
        if let data = userDefaults.data(forKey: messagesKey),
           let savedMessages = try? JSONDecoder().decode([String: [ChatMessage]].self, from: data) {
            messages = savedMessages
        }
    }
    
    private func saveData() {
        if let data = try? JSONEncoder().encode(conversations) {
            userDefaults.set(data, forKey: conversationsKey)
        }
        
        if let data = try? JSONEncoder().encode(messages) {
            userDefaults.set(data, forKey: messagesKey)
        }
    }
    
    // MARK: - Message Handling
    func getMessages(for friendId: String) -> [ChatMessage] {
        return messages[friendId] ?? []
    }
    
    func sendMessage(text: String, to friendId: String, friendName: String, currentUserId: String) {
        // Security: Input Validation
        let limit = 500
        var sanitizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitizedText.count > limit {
            sanitizedText = String(sanitizedText.prefix(limit))
        }
        guard !sanitizedText.isEmpty else { return }
        
        let newMessage = ChatMessage(senderId: currentUserId, text: sanitizedText, isRead: true)
        
        // Add to messages
        if messages[friendId] != nil {
            messages[friendId]?.append(newMessage)
        } else {
            messages[friendId] = [newMessage]
        }
        
        // Update conversation
        updateConversation(friendId: friendId, friendName: friendName, lastMessage: text, time: Date(), incrementUnread: false)
        
        saveData()
        
        // Simulate reply
        simulateReply(from: friendId, friendName: friendName)
    }
    
    private func updateConversation(friendId: String, friendName: String, lastMessage: String, time: Date, incrementUnread: Bool) {
        if let index = conversations.firstIndex(where: { $0.id == friendId }) {
            var conversation = conversations[index]
            conversation.lastMessage = lastMessage
            conversation.lastMessageTime = time
            if incrementUnread {
                conversation.unreadCount += 1
            } else {
                conversation.unreadCount = 0 // Reset if we successfully sent/read
            }
            conversations[index] = conversation
            
            // Move to top
            let movedConversation = conversations.remove(at: index)
            conversations.insert(movedConversation, at: 0)
        } else {
            // New conversation
            let newConversation = Conversation(
                id: friendId,
                friendName: friendName,
                lastMessage: lastMessage,
                lastMessageTime: time,
                unreadCount: incrementUnread ? 1 : 0
            )
            conversations.insert(newConversation, at: 0)
        }
    }
    
    func markAsRead(friendId: String) {
        guard let index = conversations.firstIndex(where: { $0.id == friendId }) else { return }
        conversations[index].unreadCount = 0
        saveData()
    }
    
    // MARK: - Simulation
    private func simulateReply(from friendId: String, friendName: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2...5)) { [weak self] in
            guard let self = self else { return }
            
            let replies = [
                "Hey! How's it going?",
                "I'm at the library right now.",
                "Want to grab lunch later?",
                "Just finished class.",
                "Cool!",
                "See you soon.",
                "Did you see the new campus event?",
                "On my way!"
            ]
            
            let replyText = replies.randomElement() ?? "Hello!"
            let message = ChatMessage(senderId: friendId, text: replyText, timestamp: Date(), isRead: false)
            
            if self.messages[friendId] != nil {
                self.messages[friendId]?.append(message)
            } else {
                self.messages[friendId] = [message]
            }
            
            self.updateConversation(friendId: friendId, friendName: friendName, lastMessage: replyText, time: Date(), incrementUnread: true)
            self.saveData()
        }
    }
}
