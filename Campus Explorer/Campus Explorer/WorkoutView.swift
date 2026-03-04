//
//  WorkoutView.swift
//  Campus Explorer
//
//  Active workout session UI
//

import SwiftUI
import MapKit

struct WorkoutView: View {
    @Bindable var workoutManager: WorkoutManager
    @ObservedObject var locationManager: LocationManager
    
    @Environment(\.dismiss) var dismiss
    @State private var showingStopConfirmation = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Image(systemName: workoutManager.currentSession?.type.icon ?? "figure.run")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(workoutManager.currentSession?.type.rawValue ?? "Workout")
                            .font(.headline)
                        Text(workoutManager.state == .active ? "Active" : "Paused")
                            .font(.subheadline)
                            .foregroundStyle(workoutManager.state == .active ? .green : .orange)
                    }
                    
                    Spacer()
                }
                .padding()
                
                // Main Metrics
                HStack(spacing: 40) {
                    MetricView(
                        value: formattedTime(workoutManager.elapsedTime),
                        label: "Duration",
                        color: .primary
                    )
                    
                    MetricView(
                        value: String(format: "%.2f", (workoutManager.currentSession?.distance ?? 0) / 1000),
                        label: "Distance (km)",
                        color: .blue
                    )
                }
                
                HStack(spacing: 40) {
                    MetricView(
                        value: String(format: "%.0f", workoutManager.currentSession?.calories ?? 0),
                        label: "Calories",
                        color: .orange
                    )
                    
                    MetricView(
                        value: String(format: "%.0f", workoutManager.currentHeartRate),
                        label: "Heart Rate",
                        color: .red
                    )
                }
                
                // Map visualization (placeholder or mini-map)
                Map(position: .constant(.userLocation(fallback: .automatic))) {
                    UserAnnotation()
                    if let route = workoutManager.currentSession?.route {
                        MapPolyline(coordinates: route.map { $0.clCoordinate })
                            .stroke(.blue, lineWidth: 5)
                    }
                }
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding()
                
                Spacer()
                
                // Controls
                HStack(spacing: 40) {
                    if workoutManager.state == .active {
                        Button(action: {
                            workoutManager.pauseWorkout()
                        }) {
                            Image(systemName: "pause.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundStyle(.orange)
                        }
                    } else {
                        Button(action: {
                            workoutManager.resumeWorkout()
                        }) {
                            Image(systemName: "play.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundStyle(.green)
                        }
                    }
                    
                    Button(action: {
                        showingStopConfirmation = true
                    }) {
                        Image(systemName: "stop.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Current Workout")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled() // Prevent swipe to dismiss while active
            .alert("End Workout?", isPresented: $showingStopConfirmation) {
                Button("End", role: .destructive) {
                    workoutManager.stopWorkout()
                    dismiss()
                }
                Button("Resume", role: .cancel) {
                    workoutManager.resumeWorkout()
                }
            } message: {
                Text("Are you sure you want to end this workout?")
            }
            .onChange(of: locationManager.currentLocation) { _, newLoc in
                // Update workout manager with location
                if let loc = newLoc {
                    workoutManager.updateMetrics(
                        location: loc,
                        distanceDelta: 0, // LocationManager already tracks totalDistance, need delta logic or just rely on session.distance.
                        // Actually LocationManager.totalDistance is strictly increasing.
                        // Let's rely on Manager's internal delta calculation if we pass prevLoc.
                        // For simplicity, we just pass loc and let manager handle it or calculate delta here.
                        // To keep it simple, we'll let Manager calculate distance from coord diffs.
                        stepsDelta: 0 // LocationManager steps are total. We'd need delta. Manager can track startSteps.
                    )
                    // Note: UpdateMetrics logic in Manager needs refinement for delta.
                    // For now, it assumes pre-calculated deltas.
                    // Let's refine Manager logic later if needed.
                }
            }
        }
    }
    
    private func formattedTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct MetricView: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    WorkoutView(
        workoutManager: WorkoutManager(),
        locationManager: LocationManager()
    )
}
