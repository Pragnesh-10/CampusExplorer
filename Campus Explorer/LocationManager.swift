// LocationManager.swift
// Campus Explorer
//
// Handles location updates, permission requests, step tracking (including Apple Watch), and saving/loading coordinates.

import Foundation
import CoreLocation
import CoreMotion
import Combine
#if os(iOS)
import HealthKit
#endif

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    // Published properties for use in SwiftUI
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var pathCoordinates: [CLLocationCoordinate2D] = []
    @Published var totalDistance: Double = 0
    @Published var stepCount: Int = 0
    @Published var isStepCountingAvailable: Bool = false
    @Published var healthKitAuthorized: Bool = false
    @Published var stepsSource: String = "Device" // "Device", "Apple Watch", or "HealthKit"
    
    private let locationManager = CLLocationManager()
    private let pedometer = CMPedometer()
    private let coordinatesKey = "visitedCoordinates"
    private let stepsKey = "totalSteps"
    private let stepsStartDateKey = "stepsStartDate"
    
    #if os(iOS)
    private let healthStore = HKHealthStore()
    private var healthKitQuery: HKObserverQuery?
    #endif

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .fitness
        loadPath()
        loadSteps()
        
        // Get initial authorization status
        authorizationStatus = locationManager.authorizationStatus
        
        // Check if step counting is available (iOS only)
        #if os(iOS)
        isStepCountingAvailable = CMPedometer.isStepCountingAvailable() || HKHealthStore.isHealthDataAvailable()
        #else
        isStepCountingAvailable = false
        #endif
    }
    
    // MARK: - Permission
    func requestPermission() {
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            #if os(iOS)
            locationManager.requestWhenInUseAuthorization()
            #else
            // macOS requires requesting location authorization
            locationManager.requestWhenInUseAuthorization()
            #endif
        } else {
            // Already determined, update status and start if authorized
            authorizationStatus = status
            #if os(iOS)
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                startTracking()
            }
            #else
            if status == .authorized || status == .authorizedAlways {
                startTracking()
            }
            #endif
        }
    }

    // MARK: - Start/Stop Updates
    func startTracking() {
        locationManager.startUpdatingLocation()
        startStepCounting()
        #if os(iOS)
        requestHealthKitAuthorization()
        #endif
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        stopStepCounting()
        #if os(iOS)
        stopHealthKitUpdates()
        #endif
    }
    
    // MARK: - HealthKit (Apple Watch Integration)
    #if os(iOS)
    func requestHealthKitAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available")
            return
        }
        
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }
        
        let typesToRead: Set<HKObjectType> = [stepType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.healthKitAuthorized = success
                if success {
                    self?.startHealthKitStepUpdates()
                } else {
                    // Fall back to pedometer
                    self?.startPedometerUpdates()
                }
            }
        }
    }
    
    private func startHealthKitStepUpdates() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }
        
        // Query for today's steps (includes Apple Watch data)
        queryHealthKitSteps()
        
        // Set up observer for real-time updates
        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, _, error in
            if error == nil {
                self?.queryHealthKitSteps()
            }
        }
        
        healthKitQuery = query
        healthStore.execute(query)
        
        // Enable background delivery for step updates
        healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate) { _, _ in }
    }
    
    private func queryHealthKitSteps() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }
        
        let startDate = getStepsStartDate()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                return
            }
            
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            
            DispatchQueue.main.async {
                // Check if steps are from Apple Watch
                self?.stepCount = steps
                self?.stepsSource = "HealthKit (incl. Apple Watch)"
                self?.saveSteps()
            }
        }
        
        healthStore.execute(query)
    }
    
    private func stopHealthKitUpdates() {
        if let query = healthKitQuery {
            healthStore.stop(query)
            healthKitQuery = nil
        }
    }
    #endif
    
    // MARK: - Pedometer Step Counting (Fallback)
    private func startStepCounting() {
        #if os(iOS)
        // HealthKit will be used if authorized, this is fallback
        if !healthKitAuthorized {
            startPedometerUpdates()
        }
        #endif
    }
    
    private func startPedometerUpdates() {
        #if os(iOS)
        guard CMPedometer.isStepCountingAvailable() else {
            print("Step counting not available")
            return
        }
        
        // Get start date (use saved date or now)
        let startDate = getStepsStartDate()
        
        // Query historical steps from start date
        pedometer.queryPedometerData(from: startDate, to: Date()) { [weak self] data, error in
            if let data = data {
                DispatchQueue.main.async {
                    self?.stepCount = data.numberOfSteps.intValue
                    self?.stepsSource = "Device"
                    self?.saveSteps()
                }
            }
        }
        
        // Start live updates
        pedometer.startUpdates(from: startDate) { [weak self] data, error in
            if let data = data {
                DispatchQueue.main.async {
                    self?.stepCount = data.numberOfSteps.intValue
                    self?.stepsSource = "Device"
                    self?.saveSteps()
                }
            }
        }
        #endif
    }
    
    private func stopStepCounting() {
        #if os(iOS)
        pedometer.stopUpdates()
        #endif
    }
    
    private func getStepsStartDate() -> Date {
        if let savedDate = UserDefaults.standard.object(forKey: stepsStartDateKey) as? Date {
            return savedDate
        } else {
            let now = Date()
            UserDefaults.standard.set(now, forKey: stepsStartDateKey)
            return now
        }
    }

    // MARK: - CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        #if os(iOS)
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startTracking()
        }
        #else
        if authorizationStatus == .authorized {
            startTracking()
        }
        #endif
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Calculate distance from last location
        if let lastLocation = currentLocation {
            totalDistance += location.distance(from: lastLocation)
        }
        
        currentLocation = location
        appendCoordinate(location.coordinate)
    }
    
    // MARK: - Save/Load Visited Path
    private func appendCoordinate(_ coordinate: CLLocationCoordinate2D) {
        // Only add if sufficiently far from last, to avoid duplicates
        if let last = pathCoordinates.last {
            let lastLoc = CLLocation(latitude: last.latitude, longitude: last.longitude)
            let newLoc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            if newLoc.distance(from: lastLoc) < 3.0 { return } // threshold in meters
        }
        pathCoordinates.append(coordinate)
        savePath()
    }
    
    private func savePath() {
        let array = pathCoordinates.map { [$0.latitude, $0.longitude] }
        UserDefaults.standard.set(array, forKey: coordinatesKey)
    }
    
    private func loadPath() {
        guard let array = UserDefaults.standard.array(forKey: coordinatesKey) as? [[Double]] else { return }
        let coords = array.map { CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1]) }
        totalDistance = 0
        pathCoordinates = coords
    }
    
    private func saveSteps() {
        UserDefaults.standard.set(stepCount, forKey: stepsKey)
    }
    
    private func loadSteps() {
        stepCount = UserDefaults.standard.integer(forKey: stepsKey)
    }
    
    // Reset data and clear saved path
    func resetPath() {
        pathCoordinates = []
        totalDistance = 0
        stepCount = 0
        UserDefaults.standard.removeObject(forKey: coordinatesKey)
        UserDefaults.standard.removeObject(forKey: stepsKey)
        UserDefaults.standard.removeObject(forKey: stepsStartDateKey)
        
        // Restart step counting from now
        #if os(iOS)
        stopStepCounting()
        startStepCounting()
        #endif
    }
}
