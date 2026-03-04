//
//  AuthView.swift
//  Campus Explorer
//
//  Legacy authentication view (no longer used - app auto-generates codes)
//

import SwiftUI

// Note: This view is no longer used in the app.
// The app now auto-generates friend codes on first launch.
// Entry point is now MainTabView in ContentView.swift

struct AuthView: View {
    @StateObject private var authManager = AuthManager()
    
    var body: some View {
        // Redirect directly to main tabs since we auto-generate codes now
        MainTabView()
            .environmentObject(authManager)
    }
}

#Preview {
    AuthView()
}
