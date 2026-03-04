//
//  ChallengesView.swift
//  Campus Explorer
//
//  Display active and completed challenges
//

import SwiftUI

struct ChallengesView: View {
    @Bindable var challengesManager: ChallengesManager
    
    @State private var showingCreateChallenge = false
    
    var body: some View {
        NavigationStack {
            List {
                if challengesManager.activeChallenges.isEmpty {
                    ContentUnavailableView(
                        "No Active Challenges",
                        systemImage: "flag.slash",
                        description: Text("Join a challenge to start competing!")
                    )
                } else {
                        ForEach(challengesManager.activeChallenges) { challenge in
                            SocialChallengeRow(challenge: challenge)
                        }
                    }

                
                if !challengesManager.completedChallenges.isEmpty {
                    Section("Completed") {
                        ForEach(challengesManager.completedChallenges) { challenge in
                            SocialChallengeRow(challenge: challenge)
                        }
                    }
                }
            }
            .navigationTitle("Challenges")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Create challenge sheet
                        showingCreateChallenge = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateChallenge) {
                // Placeholder for creation sheet
                Text("Create New Challenge")
                    .presentationDetents([.medium])
            }
        }
    }
}

struct SocialChallengeRow: View {
    let challenge: SocialChallenge
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(challenge.title)
                    .font(.headline)
                Spacer()
                if challenge.isCompleted {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                } else {
                    Text("Due \(challenge.deadline, style: .date)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text(challenge.description)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Progress Bar
            VStack(spacing: 4) {
                ProgressView(value: challenge.progress)
                    .tint(challenge.isCompleted ? .green : .blue)
                
                HStack {
                    Text(challenge.formattedCurrent)
                    Spacer()
                    Text(challenge.formattedTarget)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ChallengesView(challengesManager: ChallengesManager())
}
