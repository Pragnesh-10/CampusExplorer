//
//  NavigationView.swift
//  Campus Explorer
//
//  Turn-by-turn navigation UI
//

import SwiftUI
import MapKit

struct CampusNavigationView: View {
    @Bindable var navigationManager: NavigationManager
    @ObservedObject var locationManager: LocationManager
    
    @State private var selectedCategory: CampusBuildingCategory?
    @State private var showingRouteOptions = false
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showingAR = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if navigationManager.isNavigating, let route = navigationManager.activeRoute {
                    // Active Navigation View
                    activeNavigationView(route: route)
                } else {
                    // Search and Select Destination
                    destinationSearchView
                }
            }
            .navigationTitle(navigationManager.isNavigating ? "Navigating" : "Navigation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button {
                            showingAR = true
                        } label: {
                            Image(systemName: "camera.viewfinder")
                        }
                        
                        if navigationManager.isNavigating {
                            Button("End") {
                                navigationManager.stopNavigation()
                            }
                            .foregroundStyle(.red)
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showingAR) {
                ARNavigationView(locationManager: locationManager)
            }
        }
    }
    
    // MARK: - Destination Search View
    private var destinationSearchView: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search buildings...", text: Binding(
                    get: { navigationManager.searchQuery },
                    set: { navigationManager.search($0) }
                ))
                .textFieldStyle(.plain)
                
                if !navigationManager.searchQuery.isEmpty {
                    Button {
                        navigationManager.searchQuery = ""
                        navigationManager.searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    CategoryPill(title: "All", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }
                    
                    ForEach(CampusBuildingCategory.allCases, id: \.self) { category in
                        CategoryPill(
                            title: category.rawValue,
                            icon: category.icon,
                            color: category.color,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
            
            Divider()
            
            // Results List
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Recent Destinations
                    if navigationManager.searchQuery.isEmpty && !navigationManager.recentDestinations.isEmpty {
                        Section {
                            ForEach(navigationManager.recentDestinations) { building in
                                BuildingRow(building: building) {
                                    selectDestination(building)
                                }
                            }
                        } header: {
                            SectionHeader(title: "Recent")
                        }
                    }
                    
                    // Search Results or All Buildings
                    let buildings = navigationManager.searchQuery.isEmpty
                        ? navigationManager.filterByCategory(selectedCategory)
                        : navigationManager.searchResults
                    
                    Section {
                        ForEach(buildings) { building in
                            BuildingRow(building: building) {
                                selectDestination(building)
                            }
                        }
                    } header: {
                        if !navigationManager.searchQuery.isEmpty {
                            SectionHeader(title: "Results")
                        } else {
                            SectionHeader(title: "All Buildings")
                        }
                    }
                }
                .padding(.vertical)
            }
            
            // Loading or Error
            if navigationManager.isCalculatingRoute {
                ProgressView("Calculating route...")
                    .padding()
            }
            
            if let error = navigationManager.routeError {
                Text(error)
                    .foregroundStyle(.red)
                    .padding()
            }
        }
    }
    
    // MARK: - Active Navigation View
    private func activeNavigationView(route: ActiveRoute) -> some View {
        VStack(spacing: 0) {
            // Map with Route
            Map(position: $cameraPosition) {
                // Route polyline
                MapPolyline(route.route.polyline)
                    .stroke(.blue, lineWidth: 5)
                
                // User location
                UserAnnotation()
                
                // Destination marker
                if let destination = route.destination {
                    Annotation(destination.name, coordinate: destination.coordinate) {
                        Image(systemName: "flag.fill")
                            .font(.title)
                            .foregroundStyle(.red)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .frame(height: 300)
            
            // Current Step Card
            if let currentStep = route.currentStep {
                CurrentStepCard(step: currentStep)
                    .padding()
            }
            
            // Route Info
            HStack(spacing: 30) {
                VStack {
                    Text(formatDistance(route.remainingDistance))
                        .font(.title2.bold())
                    Text("Distance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack {
                    Text(route.formattedETA)
                        .font(.title2.bold())
                    Text("ETA")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack {
                    Text("\(route.currentStepIndex + 1)/\(route.steps.count)")
                        .font(.title2.bold())
                    Text("Steps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // All Steps List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(route.steps.enumerated()), id: \.element.id) { index, step in
                        StepRow(
                            step: step,
                            stepNumber: index + 1,
                            isCurrentStep: index == route.currentStepIndex,
                            isCompleted: index < route.currentStepIndex
                        )
                    }
                }
                .padding()
            }
            
            // Controls
            HStack(spacing: 16) {
                Button {
                    navigationManager.isVoiceGuidanceEnabled.toggle()
                } label: {
                    Image(systemName: navigationManager.isVoiceGuidanceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.title2)
                        .frame(width: 50, height: 50)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                
                Button {
                    showingRouteOptions = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .frame(width: 50, height: 50)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Button {
                    navigationManager.stopNavigation()
                } label: {
                    Text("End Navigation")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingRouteOptions) {
            RouteOptionsSheet(
                navigationManager: navigationManager,
                currentRoute: route
            )
            .presentationDetents([.medium])
        }
        .onAppear {
            // Center on route
            let region = MKCoordinateRegion(route.route.polyline.boundingMapRect)
            cameraPosition = .region(region)
        }
    }
    
    // MARK: - Helper Functions
    private func selectDestination(_ building: CampusBuilding) {
        guard let userLocation = locationManager.currentLocation?.coordinate else { return }
        
        Task {
            await navigationManager.calculateRoute(
                from: userLocation,
                to: building,
                routeType: navigationManager.selectedRouteType
            )
            
            if navigationManager.activeRoute != nil {
                navigationManager.startNavigation()
            }
        }
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return "\(Int(distance)) m"
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
}

// MARK: - Supporting Views
struct CategoryPill: View {
    let title: String
    var icon: String? = nil
    var color: Color = .blue
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct BuildingRow: View {
    let building: CampusBuilding
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: building.category.icon)
                    .font(.title2)
                    .foregroundStyle(building.category.color)
                    .frame(width: 44, height: 44)
                    .background(building.category.color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 8) {
                        Text(building.shortName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if building.hasAccessibleEntrance {
                            Image(systemName: "figure.roll")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
        .buttonStyle(.plain)
        
        Divider()
            .padding(.leading, 72)
    }
}

struct CurrentStepCard: View {
    let step: RouteStep
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: step.maneuverType.rawValue)
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(Color.blue)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(step.instruction)
                    .font(.headline)
                Text("in \(step.formattedDistance)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct StepRow: View {
    let step: RouteStep
    let stepNumber: Int
    let isCurrentStep: Bool
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : (isCurrentStep ? Color.blue : Color(.systemGray4)))
                    .frame(width: 32, height: 32)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                } else {
                    Text("\(stepNumber)")
                        .font(.caption.bold())
                        .foregroundStyle(isCurrentStep ? .white : .primary)
                }
            }
            
            Image(systemName: step.maneuverType.rawValue)
                .font(.body)
                .foregroundStyle(isCurrentStep ? .blue : .secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(step.instruction)
                    .font(.subheadline)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                Text(step.formattedDistance)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isCurrentStep ? Color.blue.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct RouteOptionsSheet: View {
    @Bindable var navigationManager: NavigationManager
    let currentRoute: ActiveRoute
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Route Type") {
                    ForEach(RouteType.allCases) { type in
                        Button {
                            navigationManager.selectedRouteType = type
                            // Recalculate route with new type
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundStyle(.blue)
                                Text(type.rawValue)
                                Spacer()
                                if type == currentRoute.routeType {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
                
                Section("Settings") {
                    Toggle(isOn: $navigationManager.isVoiceGuidanceEnabled) {
                        Label("Voice Guidance", systemImage: "speaker.wave.2")
                    }
                }
                
                if !navigationManager.alternativeRoutes.isEmpty {
                    Section("Alternative Routes") {
                        ForEach(Array(navigationManager.alternativeRoutes.enumerated()), id: \.offset) { index, route in
                            Button {
                                navigationManager.selectAlternativeRoute(route)
                                dismiss()
                            } label: {
                                HStack {
                                    Text("Route \(index + 2)")
                                    Spacer()
                                    Text(formatDistance(route.distance))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Route Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return "\(Int(distance)) m"
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
}

#Preview {
    CampusNavigationView(
        navigationManager: NavigationManager(),
        locationManager: LocationManager()
    )
}
