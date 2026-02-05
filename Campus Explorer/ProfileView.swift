//
//  ProfileView.swift
//  Campus Explorer
//
//  User profile view
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        NavigationView {
            List {
                // User Info Section
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.blue)
                        
                        VStack(spacing: 4) {
                            Text(authManager.currentUser?.username ?? "Explorer")
                                .font(.title2)
                                .bold()
                            Text("Code: \(authManager.userCode)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                
                // Stats Section
                Section("Statistics") {
                    HStack {
                        Image(systemName: "figure.walk")
                            .foregroundStyle(.green)
                        Text("Total Distance")
                        Spacer()
                        Text(String(format: "%.2f km", locationManager.totalDistance / 1000))
                            .foregroundStyle(.secondary)
                    }
                    
                    #if os(iOS)
                    if locationManager.isStepCountingAvailable {
                        HStack {
                            // Show Apple Watch icon if using HealthKit
                            if locationManager.stepsSource.contains("Apple Watch") || locationManager.stepsSource.contains("HealthKit") {
                                Image(systemName: "applewatch")
                                    .foregroundStyle(.green)
                            } else {
                                Image(systemName: "shoeprints.fill")
                                    .foregroundStyle(.orange)
                            }
                            VStack(alignment: .leading) {
                                Text("Total Steps")
                                if locationManager.stepsSource.contains("Apple Watch") || locationManager.stepsSource.contains("HealthKit") {
                                    Text("via Apple Watch")
                                        .font(.caption2)
                                        .foregroundStyle(.green)
                                }
                            }
                            Spacer()
                            Text("\(locationManager.stepCount)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    #endif
                    
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundStyle(.blue)
                        Text("Connected Friends")
                        Spacer()
                        Text("\(authManager.currentUser?.friendIds.count ?? 0)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "map.fill")
                            .foregroundStyle(.purple)
                        Text("Path Points")
                        Spacer()
                        Text("\(locationManager.pathCoordinates.count)")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Actions Section
                Section {
                    Button(role: .destructive) {
                        authManager.resetAccount()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Reset Account & Get New Code")
                        }
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}
