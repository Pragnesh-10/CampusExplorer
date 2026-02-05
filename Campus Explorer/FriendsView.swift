//
//  FriendsView.swift
//  Campus Explorer
//
//  Friends list and connect via code
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

struct FriendsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var friendCode = ""
    @State private var friends: [UserProfile] = []
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            List {
                // My Code Section
                Section {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Your Friend Code")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(authManager.userCode)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(.blue)
                            }
                            
                            Spacer()
                            
                            Button {
                                #if os(iOS)
                                UIPasteboard.general.string = authManager.userCode
                                #else
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(authManager.userCode, forType: .string)
                                #endif
                                showSuccess = true
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: "doc.on.doc.fill")
                                        .font(.title2)
                                    Text("Copy")
                                        .font(.caption)
                                }
                                .foregroundStyle(.blue)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        Text("Share this code with friends to connect")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Add Friend Section
                Section("Connect with Friend") {
                    HStack {
                        TextField("Enter friend's code", text: $friendCode)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            #else
                            .textFieldStyle(.roundedBorder)
                            #endif
                        
                        Button {
                            connectWithFriend()
                        } label: {
                            Image(systemName: "person.badge.plus")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(.green)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(friendCode.count != 6)
                    }
                    
                    if showError {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    
                    if showSuccess {
                        Text("Code copied to clipboard!")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                
                // Current Friends Section
                Section("Connected Friends") {
                    if friends.isEmpty {
                        Text("No friends connected yet")
                            .foregroundStyle(.secondary)
                            .italic()
                    } else {
                        ForEach(friends) { friend in
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                
                                VStack(alignment: .leading) {
                                    Text(friend.username)
                                        .font(.headline)
                                    Text("Code: \(friend.id)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Button {
                                    authManager.removeFriend(friendId: friend.id)
                                    loadFriends()
                                } label: {
                                    Image(systemName: "person.fill.xmark")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Friends")
            .onAppear {
                loadFriends()
            }
            .onChange(of: showSuccess) { _, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showSuccess = false
                    }
                }
            }
            .onChange(of: showError) { _, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showError = false
                    }
                }
            }
        }
    }
    
    private func connectWithFriend() {
        showError = false
        showSuccess = false
        
        guard friendCode.count == 6 else {
            errorMessage = "Code must be 6 digits"
            showError = true
            return
        }
        
        if authManager.connectWithFriend(friendCode: friendCode) {
            friendCode = ""
            loadFriends()
            errorMessage = "Friend connected successfully!"
            showSuccess = true
        } else {
            if friendCode == authManager.userCode {
                errorMessage = "You can't add yourself!"
            } else {
                errorMessage = "Already connected with this friend"
            }
            showError = true
        }
    }
    
    private func loadFriends() {
        friends = authManager.getFriends()
    }
}

#Preview {
    FriendsView()
        .environmentObject(AuthManager())
}
