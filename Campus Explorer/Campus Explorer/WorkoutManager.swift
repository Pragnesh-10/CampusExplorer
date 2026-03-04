//
//  WorkoutManager.swift
//  Campus Explorer
//
//  Manages workout sessions and fitness tracking
//

import Foundation
import CoreLocation
import Observation

enum WorkoutState {
    case idle
    case active
    case paused
}

enum WorkoutType: String, CaseIterable, Codable {
    case walk = "Outdoor Walk"
    case run = "Outdoor Run"
    case cycle = "Outdoor Cycle"
    case hike = "Hiking"
    case custom = "Custom"
    
    var icon: String {
        switch self {
        case .walk: return "figure.walk"
        case .run: return "figure.run"
        case .cycle: return "bicycle"
        case .hike: return "figure.hiking"
        case .custom: return "figure.mixed.cardio"
        }
    }
}

struct WorkoutSession: Identifiable, Codable {
    let id: UUID
    let type: WorkoutType
    let startTime: Date
    var endTime: Date?
    var distance: Double // meters
    var calories: Double
    var steps: Int
    var route: [CodableCoordinate]
    var heartRateData: [Double] // Mocked for now
    
    var duration: TimeInterval {
        return (endTime ?? Date()).timeIntervalSince(startTime)
    }
}

@Observable
class WorkoutManager {
    var state: WorkoutState = .idle
    var currentSession: WorkoutSession?
    var workoutHistory: [WorkoutSession] = []
    var elapsedTime: TimeInterval = 0
    var currentPace: Double = 0 // min/km
    var currentHeartRate: Double = 0
    
    private var timer: Timer?
    private let userDefaults = UserDefaults.standard
    private let historyKey = "workout_history"
    
    init() {
        loadHistory()
    }
    
    // MARK: - Workout Control
    func startWorkout(type: WorkoutType) {
        let session = WorkoutSession(
            id: UUID(),
            type: type,
            startTime: Date(),
            endTime: nil,
            distance: 0,
            calories: 0,
            steps: 0,
            route: [],
            heartRateData: []
        )
        currentSession = session
        state = .active
        elapsedTime = 0
        startTimer()
    }
    
    func pauseWorkout() {
        state = .paused
        timer?.invalidate()
    }
    
    func resumeWorkout() {
        state = .active
        startTimer()
    }
    
    func stopWorkout() {
        guard var session = currentSession else { return }
        session.endTime = Date()
        workoutHistory.append(session)
        saveHistory()
        
        currentSession = nil
        state = .idle
        timer?.invalidate()
        elapsedTime = 0
    }
    
    func updateMetrics(location: CLLocation?, distanceDelta: Double, stepsDelta: Int) {
        guard state == .active, var session = currentSession else { return }
        
        // Update Session Data
        session.distance += distanceDelta
        session.steps += stepsDelta
        
        // Calculate Calories (Rough Estimate)
        // MET values: Walk ~3.5, Run ~8, Cycle ~6
        let met: Double
        switch session.type {
        case .walk: met = 3.5
        case .run: met = 8.0
        case .cycle: met = 6.0
        case .hike: met = 6.0
        case .custom: met = 5.0
        }
        
        // Calories = MET * Weight(kg) * Time(hours)
        // Assume 70kg weight for now
        let caloriesPerSecond = (met * 70) / 3600
        session.calories += caloriesPerSecond // Added per second in timer normally, but here we approximate
        
        // Update Route
        if let loc = location {
            session.route.append(CodableCoordinate(loc.coordinate))
            
            // Pace (min/km)
            // Speed is m/s. Pace = 16.66 / speed
            if loc.speed > 0 {
                currentPace = 16.66 / loc.speed
            }
        }
        
        // Mock Heart Rate
        let baseHR = 70.0
        let intensityFactor = min(1.0, distanceDelta / 5.0) // Arbitrary intensity
        currentHeartRate = baseHR + (intensityFactor * 100) + Double.random(in: -5...5)
        session.heartRateData.append(currentHeartRate)
        
        currentSession = session
    }
    
    // MARK: - Timer
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.state == .active else { return }
            self.elapsedTime += 1
            
            // Add baseline calories for time passed
            if var session = self.currentSession {
                // simple calorie increment based on type
                let calPerSec: Double
                switch session.type {
                case .walk: calPerSec = 0.08
                case .run: calPerSec = 0.2
                case .cycle: calPerSec = 0.15
                default: calPerSec = 0.1
                }
                session.calories += calPerSec
                
                // Mock HR fluctuation
                if self.currentHeartRate == 0 { self.currentHeartRate = 80 }
                self.currentHeartRate += Double.random(in: -2...2)
                
                self.currentSession = session
            }
        }
    }
    
    // MARK: - Persistence
    private func loadHistory() {
        if let data = userDefaults.data(forKey: historyKey),
           let history = try? JSONDecoder().decode([WorkoutSession].self, from: data) {
            workoutHistory = history
        }
    }
    
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(workoutHistory) {
            userDefaults.set(data, forKey: historyKey)
        }
    }
}
