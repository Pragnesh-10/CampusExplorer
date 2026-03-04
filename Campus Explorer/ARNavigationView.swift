//
//  ARNavigationView.swift
//  Campus Explorer
//
//  AR View for navigation and treasure hunt
//

import SwiftUI
import ARKit
import RealityKit
import CoreLocation
import Combine

struct ARNavigationView: View {
    @State private var arManager = ARManager()
    @State private var treasureManager = TreasureHuntManager()
    @ObservedObject var locationManager: LocationManager
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // AR Camera Feed
            ARViewContainer(arManager: arManager)
                .edgesIgnoringSafeArea(.all)
            
            // UI Overlay
            VStack {
                // Top Bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Tracking Status
                    Text(arManager.trackingStatus)
                        .font(.caption)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    // Score
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text("\(treasureManager.totalPoints)")
                            .foregroundStyle(.white)
                            .bold()
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(20)
                }
                .padding()
                
                Spacer()
                
                // Treasure Hint / Action
                if let nearest = treasureManager.nearestItem {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "diamond.fill")
                                .foregroundStyle(.cyan)
                            Text("Treasure Nearby")
                                .font(.headline)
                        }
                        
                        Text(nearest.name)
                            .font(.title3)
                            .bold()
                        
                        HStack {
                            Image(systemName: "location.fill")
                            Text("\(Int(treasureManager.distanceToNearest))m away")
                        }
                        .foregroundStyle(.secondary)
                        
                        Text(nearest.hint)
                            .italic()
                            .multilineTextAlignment(.center)
                            .font(.caption)
                        
                        if treasureManager.distanceToNearest < 20 { // 20m range
                            Button {
                                treasureManager.collectItem(nearest)
                            } label: {
                                Text("Collect Item")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding()
                } else {
                    Text("Explore campus to find treasures!")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            arManager.startSession()
        }
        .onDisappear {
            arManager.pauseSession()
        }
        .onChange(of: locationManager.currentLocation) { _, newLoc in
            if let loc = newLoc {
                treasureManager.checkProximity(userLocation: loc)
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    var arManager: ARManager
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arManager.arView = arView
        arView.session = arManager.session
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

#Preview {
    ARNavigationView(locationManager: LocationManager())
}
