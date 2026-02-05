// ContentView.swift
// Campus Explorer
//
// Main map explorer view (renamed to MapExplorerView)

import SwiftUI
import MapKit

struct MapExplorerView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var showInfo = false
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    
    // Fallback region for SRM University AP
    private var fallbackRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 16.4350, longitude: 80.5104),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    // Estimate progress: unique grid cells visited divided by grid count in region
    private func explorationProgress() -> Double {
        // Divide region into 100x100m cells, count unique visited
        let gridSize = 0.001 // ~111m in latitude
        let coords = locationManager.pathCoordinates
        guard !coords.isEmpty else { return 0 }
        // Use a hashable struct for grid cells
        struct GridCell: Hashable {
            let x: Int
            let y: Int
        }
        let cells = Set(coords.map { GridCell(x: Int($0.latitude / gridSize), y: Int($0.longitude / gridSize)) })
        // Assume a visible region of about 1km^2
        let totalCells = 10 * 10
        return min(Double(cells.count) / Double(totalCells), 1)
    }

    // Helper to check if location is authorized
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
            // Check location authorization status
            if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                // Location access denied - show prompt
                locationDeniedView
            } else if locationManager.authorizationStatus == .notDetermined {
                // Waiting for permission - show request view
                locationRequestView
            } else if isLocationAuthorized {
                // Location authorized - show map
                mapContentView
            } else {
                // Fallback - show map anyway
                mapContentView
            }
        }
        .sheet(isPresented: $showInfo) {
            InfoView()
        }
    }
    
    // MARK: - Location Permission Request View
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
                .padding(.top, 16)
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
                #else
                Text("Go to System Settings > Privacy & Security > Location Services")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
                #endif
            }
        }
    }
    
    // MARK: - Map Content View
    private var mapContentView: some View {
        ZStack {
            // MapKit Map with user tracking and overlay, updated for iOS 17 SwiftUI API
            Map(position: $cameraPosition, interactionModes: .all) {
                if !locationManager.pathCoordinates.isEmpty {
                    MapPolyline(coordinates: locationManager.pathCoordinates)
                        .stroke(.green, lineWidth: 6)
                }
                UserAnnotation()
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }

            // Top overlay: Progress + Buttons
            VStack {
                VStack(spacing: 12) {
                    // ProgressView
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Campus Explorer")
                                .font(.headline)
                                .bold()
                            Spacer()
                            Text("\(Int(explorationProgress() * 100))%")
                                .font(.title2)
                                .bold()
                                .foregroundStyle(.green)
                        }
                        
                        ProgressView(value: explorationProgress())
                            .progressViewStyle(.linear)
                            .tint(.green)
                        
                        // Stats Row: Distance and Steps
                        HStack(spacing: 20) {
                            // Distance
                            HStack(spacing: 6) {
                                Image(systemName: "figure.walk")
                                    .foregroundStyle(.blue)
                                Text(String(format: "%.1f km", locationManager.totalDistance / 1000))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            // Steps (iOS only)
                            #if os(iOS)
                            if locationManager.isStepCountingAvailable {
                                HStack(spacing: 6) {
                                    // Show Apple Watch icon if using HealthKit
                                    if locationManager.stepsSource.contains("Apple Watch") || locationManager.stepsSource.contains("HealthKit") {
                                        Image(systemName: "applewatch")
                                            .foregroundStyle(.green)
                                    } else {
                                        Image(systemName: "shoeprints.fill")
                                            .foregroundStyle(.orange)
                                    }
                                    Text("\(locationManager.stepCount) steps")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            #endif
                            
                            Spacer()
                        }
                    }
                    .padding(16)
                    .background(.ultraThickMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)

                    // Button Row
                    HStack(spacing: 12) {
                        Button {
                            locationManager.resetPath()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.bordered)
                        .background(.ultraThickMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .tint(.red)

                        Button {
                            showInfo = true
                        } label: {
                            HStack {
                                Image(systemName: "info.circle")
                                Text("Info")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.bordered)
                        .background(.ultraThickMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .tint(.blue)
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 60)
                
                Spacer()
            }
        }
        .onAppear {
            locationManager.startTracking()
        }
        .onDisappear {
            locationManager.stopTracking()
        }
    }
}

// InfoView: App privacy and purpose
struct InfoView: View {
    var body: some View {
        VStack(spacing: 26) {
            Text("About Campus Explorer")
                .font(.title).bold()
                .padding(.top, 20)
            Text("Campus Explorer records your path on campus to help you discover new places. Only the locations you visit are stored locally on your device. Your data is never collected or sent anywhere. Location permission is only used while exploring, and you can reset your path at any time.")
                .multilineTextAlignment(.center)
            Spacer()
            Text("Made with SwiftUI · iOS 17+")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

// Keep ContentView as entry point for compatibility
struct ContentView: View {
    var body: some View {
        MainTabView()
            .environmentObject(AuthManager())
    }
}

#Preview {
    ContentView()
}
