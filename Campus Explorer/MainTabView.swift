//
//  MainTabView.swift
//  Campus Explorer
//
//  Main tab navigation with all features integrated
//

import SwiftUI
import MapKit

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var locationManager = LocationManager()
    @State private var achievementsManager = AchievementsManager()
    @State private var heatMapManager = HeatMapManager()
    @State private var liveLocationManager = LiveLocationManager()
    @State private var mapSettings = MapSettingsManager()
    
    var body: some View {
        TabView {
            // Main Map View with all features
            EnhancedMapView(
                locationManager: locationManager,
                achievementsManager: achievementsManager,
                heatMapManager: heatMapManager,
                liveLocationManager: liveLocationManager,
                mapSettings: mapSettings
            )
            .tabItem {
                Label("Explore", systemImage: "map.fill")
            }
            
            // Achievements & Challenges
            AchievementsView(achievementsManager: achievementsManager)
                .tabItem {
                    Label("Achievements", systemImage: "trophy.fill")
                }
            
            // Activity Feed & Social
            ActivityFeedView(
                achievementsManager: achievementsManager,
                liveLocationManager: liveLocationManager
            )
            .tabItem {
                Label("Activity", systemImage: "person.2.fill")
            }
            
            // Statistics
            StatisticsView(
                locationManager: locationManager,
                achievementsManager: achievementsManager
            )
            .tabItem {
                Label("Stats", systemImage: "chart.bar.fill")
            }
            
            // Profile & Settings
            EnhancedProfileView(
                locationManager: locationManager,
                achievementsManager: achievementsManager,
                heatMapManager: heatMapManager,
                mapSettings: mapSettings
            )
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
        }
        .environmentObject(authManager)
        .onAppear {
            // Start tracking and update achievements
            locationManager.startTracking()
        }
        .onChange(of: locationManager.stepCount) { _, newValue in
            achievementsManager.updateProgress(steps: newValue, distance: locationManager.totalDistance, pathPoints: locationManager.pathCoordinates.count, friendCount: authManager.currentUser?.friendIds.count ?? 0)
        }
        .onChange(of: locationManager.totalDistance) { _, newValue in
            achievementsManager.updateProgress(steps: locationManager.stepCount, distance: newValue, pathPoints: locationManager.pathCoordinates.count, friendCount: authManager.currentUser?.friendIds.count ?? 0)
            
            // Track location for heat map
            if let location = locationManager.currentLocation {
                heatMapManager.trackLocation(location.coordinate)
            }
        }
    }
}

// MARK: - Enhanced Map View with All Features
struct EnhancedMapView: View {
    @ObservedObject var locationManager: LocationManager
    @Bindable var achievementsManager: AchievementsManager
    @Bindable var heatMapManager: HeatMapManager
    @Bindable var liveLocationManager: LiveLocationManager
    @Bindable var mapSettings: MapSettingsManager
    
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var showMapSettings = false
    @State private var showAddPOI = false
    @State private var selectedPOI: PointOfInterest?
    @State private var longPressLocation: CLLocationCoordinate2D?
    
    // Fallback region for SRM University AP
    private var fallbackRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 16.4350, longitude: 80.5104),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    private var isLocationAuthorized: Bool {
        #if os(iOS)
        return locationManager.authorizationStatus == .authorizedWhenInUse || 
               locationManager.authorizationStatus == .authorizedAlways
        #else
        return locationManager.authorizationStatus == .authorized ||
               locationManager.authorizationStatus == .authorizedAlways
        #endif
    }
    
    var body: some View {
        ZStack {
            if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                locationDeniedView
            } else if locationManager.authorizationStatus == .notDetermined {
                locationRequestView
            } else {
                mapContentView
            }
        }
        .sheet(isPresented: $showMapSettings) {
            MapSettingsView(mapSettings: mapSettings, heatMapManager: heatMapManager)
        }
        .sheet(item: $selectedPOI) { poi in
            POIDetailView(poi: poi, heatMapManager: heatMapManager)
        }
        .sheet(isPresented: $showAddPOI) {
            if let location = longPressLocation {
                AddPOIView(heatMapManager: heatMapManager, coordinate: location)
            }
        }
    }
    
    // MARK: - Map Content View
    private var mapContentView: some View {
        ZStack {
            Map(position: $cameraPosition, interactionModes: .all) {
                // User path
                if mapSettings.showPathHistory && !locationManager.pathCoordinates.isEmpty {
                    MapPolyline(coordinates: locationManager.pathCoordinates)
                        .stroke(mapSettings.pathColor, lineWidth: mapSettings.pathWidth)
                }
                
                // User location
                UserAnnotation()
                
                // POIs
                if mapSettings.showPOIs {
                    ForEach(heatMapManager.pointsOfInterest.filter { mapSettings.enabledPOICategories.contains($0.category) }) { poi in
                        Annotation(poi.name, coordinate: poi.coordinate.clCoordinate) {
                            Button {
                                selectedPOI = poi
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(poi.category.color.opacity(0.8))
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: poi.category.iconName)
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white)
                                }
                                .overlay {
                                    if poi.isVisited {
                                        Circle()
                                            .stroke(.green, lineWidth: 3)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Friend locations
                if mapSettings.showFriendLocations && liveLocationManager.isLocationSharingEnabled {
                    ForEach(liveLocationManager.friendLocations) { friend in
                        Annotation(friend.friendName, coordinate: friend.coordinate.clCoordinate) {
                            VStack(spacing: 2) {
                                ZStack {
                                    Circle()
                                        .fill(friend.status.color)
                                        .frame(width: mapSettings.friendMarkerSize, height: mapSettings.friendMarkerSize)
                                    
                                    Text(String(friend.friendName.prefix(1)))
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                }
                                
                                Text(friend.friendName)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .mapStyle(mapSettings.selectedMapStyle.mapStyle)
            .ignoresSafeArea()
            .mapControls {
                if mapSettings.showCompass {
                    MapCompass()
                }
                if mapSettings.showScale {
                    MapScaleView()
                }
                MapUserLocationButton()
            }
            
            // Fog of War Overlay (simplified visual)
            if mapSettings.showFogOfWar {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            
            // Top Stats Overlay
            VStack {
                statsOverlay
                Spacer()
            }
            
            // Bottom Quick Actions
            VStack {
                Spacer()
                bottomActions
            }
        }
        .onAppear {
            locationManager.startTracking()
        }
    }
    
    // MARK: - Stats Overlay
    private var statsOverlay: some View {
        VStack(spacing: 12) {
            // Main Stats Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Campus Explorer")
                        .font(.headline)
                        .bold()
                    Spacer()
                    
                    // Streak indicator
                    if achievementsManager.streakData.currentStreak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            Text("\(achievementsManager.streakData.currentStreak)")
                                .bold()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.orange.opacity(0.2))
                        .clipShape(Capsule())
                    }
                }
                
                // Exploration progress
                HStack {
                    Text("Explored")
                    Spacer()
                    Text(String(format: "%.1f%%", heatMapManager.explorationPercentage))
                        .foregroundStyle(.green)
                        .bold()
                }
                
                ProgressView(value: heatMapManager.explorationPercentage / 100)
                    .progressViewStyle(.linear)
                    .tint(.green)
                
                // Stats Row
                HStack(spacing: 16) {
                    StatBadge(icon: "figure.walk", value: String(format: "%.1f km", locationManager.totalDistance / 1000), color: .blue)
                    
                    #if os(iOS)
                    if locationManager.isStepCountingAvailable {
                        StatBadge(
                            icon: locationManager.stepsSource.contains("Apple Watch") ? "applewatch" : "shoeprints.fill",
                            value: "\(locationManager.stepCount)",
                            color: .orange
                        )
                    }
                    #endif
                    
                    StatBadge(icon: "mappin.circle", value: "\(heatMapManager.visitedPOIsCount)/\(heatMapManager.pointsOfInterest.count)", color: .purple)
                    
                    Spacer()
                }
            }
            .padding(16)
            .background(.ultraThickMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
            .padding(.top, 60)
            
            // Active Challenge Banner (if any)
            if let activeChallenge = achievementsManager.challenges.first(where: { !$0.isCompleted && !$0.isExpired }) {
                HStack {
                    Image(systemName: "flag.fill")
                        .foregroundStyle(.blue)
                    Text(activeChallenge.title)
                        .font(.subheadline)
                    Spacer()
                    Text("\(activeChallenge.progress)/\(activeChallenge.requirement)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Bottom Actions
    private var bottomActions: some View {
        HStack(spacing: 12) {
            // Map Settings Button
            Button {
                showMapSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                    .frame(width: 50, height: 50)
                    .background(.ultraThickMaterial)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Quick toggles
            HStack(spacing: 8) {
                QuickToggle(
                    icon: "location.fill",
                    isOn: liveLocationManager.isLocationSharingEnabled,
                    color: .green
                ) {
                    if liveLocationManager.isLocationSharingEnabled {
                        liveLocationManager.disableLocationSharing()
                    } else {
                        liveLocationManager.enableLocationSharing()
                    }
                }
                
                QuickToggle(
                    icon: "mappin.circle.fill",
                    isOn: mapSettings.showPOIs,
                    color: .purple
                ) {
                    mapSettings.showPOIs.toggle()
                }
                
                QuickToggle(
                    icon: "person.2.fill",
                    isOn: mapSettings.showFriendLocations,
                    color: .blue
                ) {
                    mapSettings.showFriendLocations.toggle()
                }
            }
            .padding(8)
            .background(.ultraThickMaterial)
            .clipShape(Capsule())
            
            Spacer()
            
            // Reset Button
            Button {
                locationManager.resetPath()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .frame(width: 50, height: 50)
                    .background(.ultraThickMaterial)
                    .clipShape(Circle())
            }
            .tint(.red)
        }
        .padding(.horizontal)
        .padding(.bottom, 30)
    }
    
    // MARK: - Location Request View
    private var locationRequestView: some View {
        ZStack {
            LinearGradient(colors: [.blue.opacity(0.6), .green.opacity(0.6)],
                          startPoint: .topLeading,
                          endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)
                
                Text("Location Access Required")
                    .font(.title)
                    .bold()
                    .foregroundStyle(.white)
                
                Text("Campus Explorer needs access to your location to track your movements and show your exploration progress.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 32)
                
                Button {
                    locationManager.requestPermission()
                } label: {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Allow Location Access")
                    }
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 48)
            }
        }
    }
    
    // MARK: - Location Denied View
    private var locationDeniedView: some View {
        ZStack {
            Color.gray.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "location.slash.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.red)
                
                Text("Location Access Denied")
                    .font(.title)
                    .bold()
                
                Text("Please enable location access in Settings to use Campus Explorer.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
                
                #if os(iOS)
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "gear")
                        Text("Open Settings")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 48)
                #endif
            }
        }
    }
}

// MARK: - Supporting Views
struct StatBadge: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct QuickToggle: View {
    let icon: String
    let isOn: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(isOn ? color : .secondary)
                .frame(width: 36, height: 36)
                .background(isOn ? color.opacity(0.2) : Color.clear)
                .clipShape(Circle())
        }
    }
}

// MARK: - Enhanced Profile View
struct EnhancedProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var locationManager: LocationManager
    @Bindable var achievementsManager: AchievementsManager
    @Bindable var heatMapManager: HeatMapManager
    @Bindable var mapSettings: MapSettingsManager
    
    @State private var showNotificationSettings = false
    @State private var showFriends = false
    
    var body: some View {
        NavigationView {
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
                    Button {
                        showFriends = true
                    } label: {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundStyle(.blue)
                            Text("Friends")
                            Spacer()
                            Text("\(authManager.currentUser?.friendIds.count ?? 0)")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
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
            .sheet(isPresented: $showFriends) {
                FriendsView()
                    .environmentObject(authManager)
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

#Preview {
    MainTabView()
        .environmentObject(AuthManager())
}
