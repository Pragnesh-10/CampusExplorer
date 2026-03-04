//
//  NavigationManager.swift
//  Campus Explorer
//
//  Handles turn-by-turn navigation and route calculation
//

import Foundation
import MapKit
import SwiftUI

// MARK: - Route Types
enum RouteType: String, CaseIterable, Identifiable {
    case fastest = "Fastest"
    case scenic = "Scenic"
    case accessible = "Accessible"
    case indoor = "Indoor Priority"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .fastest: return "hare.fill"
        case .scenic: return "leaf.fill"
        case .accessible: return "figure.roll"
        case .indoor: return "building.2.fill"
        }
    }
    
    var transportType: MKDirectionsTransportType {
        return .walking
    }
}

// MARK: - Route Step
struct RouteStep: Identifiable {
    let id = UUID()
    let instruction: String
    let distance: CLLocationDistance
    let coordinate: CLLocationCoordinate2D
    let maneuverType: RouteManeuverType
    
    var formattedDistance: String {
        if distance < 100 {
            return "\(Int(distance)) m"
        } else if distance < 1000 {
            return "\(Int(distance / 10) * 10) m"
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
}

enum RouteManeuverType: String {
    case straight = "arrow.up"
    case turnLeft = "arrow.turn.up.left"
    case turnRight = "arrow.turn.up.right"
    case slightLeft = "arrow.up.left"
    case slightRight = "arrow.up.right"
    case uTurn = "arrow.uturn.down"
    case arrival = "mappin.circle.fill"
    case start = "circle.fill"
}

// MARK: - Campus Building
struct CampusBuilding: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let shortName: String
    let coordinate: CLLocationCoordinate2D
    let category: CampusBuildingCategory
    let floors: Int
    let hasElevator: Bool
    let hasAccessibleEntrance: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CampusBuilding, rhs: CampusBuilding) -> Bool {
        lhs.id == rhs.id
    }
}

enum CampusBuildingCategory: String, CaseIterable {
    case academic = "Academic"
    case library = "Library"
    case dining = "Dining"
    case residence = "Residence"
    case sports = "Sports"
    case admin = "Administration"
    case parking = "Parking"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .academic: return "book.fill"
        case .library: return "books.vertical.fill"
        case .dining: return "fork.knife"
        case .residence: return "house.fill"
        case .sports: return "sportscourt.fill"
        case .admin: return "building.columns.fill"
        case .parking: return "car.fill"
        case .other: return "mappin.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .academic: return .blue
        case .library: return .purple
        case .dining: return .orange
        case .residence: return .green
        case .sports: return .red
        case .admin: return .gray
        case .parking: return .cyan
        case .other: return .secondary
        }
    }
}

// MARK: - Active Route
struct ActiveRoute: Identifiable {
    let id = UUID()
    let route: MKRoute
    let destination: CampusBuilding?
    let destinationName: String
    let steps: [RouteStep]
    let routeType: RouteType
    var currentStepIndex: Int = 0
    
    var currentStep: RouteStep? {
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }
    
    var remainingDistance: CLLocationDistance {
        route.distance
    }
    
    var estimatedTime: TimeInterval {
        route.expectedTravelTime
    }
    
    var formattedETA: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: estimatedTime) ?? ""
    }
}

// MARK: - Navigation Manager
@Observable
class NavigationManager {
    // MARK: - Properties
    var campusBuildings: [CampusBuilding] = []
    var searchResults: [CampusBuilding] = []
    var searchQuery: String = ""
    var recentDestinations: [CampusBuilding] = []
    
    var activeRoute: ActiveRoute?
    var isNavigating: Bool = false
    var selectedRouteType: RouteType = .fastest
    
    var alternativeRoutes: [MKRoute] = []
    var isCalculatingRoute: Bool = false
    var routeError: String?
    
    // Voice guidance
    var isVoiceGuidanceEnabled: Bool = true
    var lastAnnouncedStepIndex: Int = -1
    
    // MARK: - Initialization
    init() {
        loadCampusBuildings()
    }
    
    // MARK: - Campus Buildings (Sample Data)
    private func loadCampusBuildings() {
        // Sample campus buildings - replace with actual campus data
        campusBuildings = [
            CampusBuilding(
                name: "Main Library",
                shortName: "LIB",
                coordinate: CLLocationCoordinate2D(latitude: 12.8231, longitude: 80.0444),
                category: .library,
                floors: 4,
                hasElevator: true,
                hasAccessibleEntrance: true
            ),
            CampusBuilding(
                name: "Engineering Block A",
                shortName: "ENG-A",
                coordinate: CLLocationCoordinate2D(latitude: 12.8235, longitude: 80.0448),
                category: .academic,
                floors: 3,
                hasElevator: true,
                hasAccessibleEntrance: true
            ),
            CampusBuilding(
                name: "Science Complex",
                shortName: "SCI",
                coordinate: CLLocationCoordinate2D(latitude: 12.8228, longitude: 80.0452),
                category: .academic,
                floors: 5,
                hasElevator: true,
                hasAccessibleEntrance: true
            ),
            CampusBuilding(
                name: "Student Center",
                shortName: "SC",
                coordinate: CLLocationCoordinate2D(latitude: 12.8225, longitude: 80.0440),
                category: .dining,
                floors: 2,
                hasElevator: false,
                hasAccessibleEntrance: true
            ),
            CampusBuilding(
                name: "Sports Complex",
                shortName: "SPORTS",
                coordinate: CLLocationCoordinate2D(latitude: 12.8240, longitude: 80.0460),
                category: .sports,
                floors: 2,
                hasElevator: false,
                hasAccessibleEntrance: true
            ),
            CampusBuilding(
                name: "Administration Building",
                shortName: "ADMIN",
                coordinate: CLLocationCoordinate2D(latitude: 12.8222, longitude: 80.0435),
                category: .admin,
                floors: 3,
                hasElevator: true,
                hasAccessibleEntrance: true
            ),
            CampusBuilding(
                name: "Hostel Block 1",
                shortName: "H1",
                coordinate: CLLocationCoordinate2D(latitude: 12.8245, longitude: 80.0465),
                category: .residence,
                floors: 4,
                hasElevator: false,
                hasAccessibleEntrance: false
            ),
            CampusBuilding(
                name: "Parking Lot A",
                shortName: "P-A",
                coordinate: CLLocationCoordinate2D(latitude: 12.8218, longitude: 80.0430),
                category: .parking,
                floors: 1,
                hasElevator: false,
                hasAccessibleEntrance: true
            )
        ]
    }
    
    // MARK: - Search
    func search(_ query: String) {
        searchQuery = query
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        let lowercased = query.lowercased()
        searchResults = campusBuildings.filter { building in
            building.name.lowercased().contains(lowercased) ||
            building.shortName.lowercased().contains(lowercased) ||
            building.category.rawValue.lowercased().contains(lowercased)
        }
    }
    
    func filterByCategory(_ category: CampusBuildingCategory?) -> [CampusBuilding] {
        guard let category = category else { return campusBuildings }
        return campusBuildings.filter { $0.category == category }
    }
    
    // MARK: - Route Calculation
    func calculateRoute(
        from source: CLLocationCoordinate2D,
        to destination: CampusBuilding,
        routeType: RouteType = .fastest
    ) async {
        isCalculatingRoute = true
        routeError = nil
        selectedRouteType = routeType
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
        request.transportType = .walking
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        
        do {
            let response = try await directions.calculate()
            
            await MainActor.run {
                guard let route = response.routes.first else {
                    self.routeError = "No route found"
                    self.isCalculatingRoute = false
                    return
                }
                
                // Store alternative routes
                self.alternativeRoutes = Array(response.routes.dropFirst())
                
                // Convert MKRoute steps to NavigationSteps
                let steps = self.convertToNavigationSteps(route.steps)
                
                self.activeRoute = ActiveRoute(
                    route: route,
                    destination: destination,
                    destinationName: destination.name,
                    steps: steps,
                    routeType: routeType
                )
                
                // Add to recent destinations
                if !self.recentDestinations.contains(where: { $0.id == destination.id }) {
                    self.recentDestinations.insert(destination, at: 0)
                    if self.recentDestinations.count > 5 {
                        self.recentDestinations.removeLast()
                    }
                }
                
                self.isCalculatingRoute = false
            }
        } catch {
            await MainActor.run {
                self.routeError = error.localizedDescription
                self.isCalculatingRoute = false
            }
        }
    }
    
    func calculateRouteToCoordinate(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        destinationName: String
    ) async {
        isCalculatingRoute = true
        routeError = nil
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        
        do {
            let response = try await directions.calculate()
            
            await MainActor.run {
                guard let route = response.routes.first else {
                    self.routeError = "No route found"
                    self.isCalculatingRoute = false
                    return
                }
                
                let steps = self.convertToNavigationSteps(route.steps)
                
                self.activeRoute = ActiveRoute(
                    route: route,
                    destination: nil,
                    destinationName: destinationName,
                    steps: steps,
                    routeType: self.selectedRouteType
                )
                
                self.isCalculatingRoute = false
            }
        } catch {
            await MainActor.run {
                self.routeError = error.localizedDescription
                self.isCalculatingRoute = false
            }
        }
    }
    
    private func convertToNavigationSteps(_ mkSteps: [MKRoute.Step]) -> [RouteStep] {
        return mkSteps.enumerated().map { index, step in
            let maneuver = determineManeuverType(instruction: step.instructions, isFirst: index == 0, isLast: index == mkSteps.count - 1)
            
            return RouteStep(
                instruction: step.instructions.isEmpty ? "Continue straight" : step.instructions,
                distance: step.distance,
                coordinate: step.polyline.coordinate,
                maneuverType: maneuver
            )
        }
    }
    
    private func determineManeuverType(instruction: String, isFirst: Bool, isLast: Bool) -> RouteManeuverType {
        if isFirst { return .start }
        if isLast { return .arrival }
        
        let lowercased = instruction.lowercased()
        if lowercased.contains("left") {
            if lowercased.contains("slight") { return .slightLeft }
            return .turnLeft
        }
        if lowercased.contains("right") {
            if lowercased.contains("slight") { return .slightRight }
            return .turnRight
        }
        if lowercased.contains("u-turn") { return .uTurn }
        
        return .straight
    }
    
    // MARK: - Navigation Control
    func startNavigation() {
        guard activeRoute != nil else { return }
        isNavigating = true
        lastAnnouncedStepIndex = -1
    }
    
    func stopNavigation() {
        isNavigating = false
        activeRoute = nil
        lastAnnouncedStepIndex = -1
    }
    
    func updateProgress(currentLocation: CLLocationCoordinate2D) {
        guard var route = activeRoute, isNavigating else { return }
        
        // Check if we've reached the current step
        if let currentStep = route.currentStep {
            let stepLocation = CLLocation(latitude: currentStep.coordinate.latitude, longitude: currentStep.coordinate.longitude)
            let userLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
            let distance = userLocation.distance(from: stepLocation)
            
            // If within 20 meters of step, move to next
            if distance < 20 && route.currentStepIndex < route.steps.count - 1 {
                route.currentStepIndex += 1
                activeRoute = route
                
                // Announce next step
                if isVoiceGuidanceEnabled && route.currentStepIndex != lastAnnouncedStepIndex {
                    announceStep(route.steps[route.currentStepIndex])
                    lastAnnouncedStepIndex = route.currentStepIndex
                }
            }
            
            // Check if arrived at destination
            if route.currentStepIndex == route.steps.count - 1 && distance < 30 {
                arriveAtDestination()
            }
        }
    }
    
    private func announceStep(_ step: RouteStep) {
        // In a real app, use AVSpeechSynthesizer
        print("Navigation: \(step.instruction) in \(step.formattedDistance)")
    }
    
    private func arriveAtDestination() {
        isNavigating = false
        // Could trigger a notification or haptic feedback
    }
    
    // MARK: - Route Options
    func selectAlternativeRoute(_ route: MKRoute) {
        guard let current = activeRoute else { return }
        let steps = convertToNavigationSteps(route.steps)
        
        activeRoute = ActiveRoute(
            route: route,
            destination: current.destination,
            destinationName: current.destinationName,
            steps: steps,
            routeType: current.routeType
        )
    }
}
