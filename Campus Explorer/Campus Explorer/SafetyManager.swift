//
//  SafetyManager.swift
//  Campus Explorer
//
//  Emergency contacts, SOS, and campus safety features
//

import Foundation
import CoreLocation
import SwiftUI
import Contacts
import MessageUI

// MARK: - Emergency Contact
struct EmergencyContact: Identifiable, Codable {
    let id: UUID
    var name: String
    var phone: String
    var relationship: String
    var isEmergencyServices: Bool
    
    init(id: UUID = UUID(), name: String, phone: String, relationship: String, isEmergencyServices: Bool = false) {
        self.id = id
        self.name = name
        self.phone = phone
        self.relationship = relationship
        self.isEmergencyServices = isEmergencyServices
    }
}

// MARK: - Blue Light Location
struct BlueLightLocation: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let type: BlueLightType
    var isOperational: Bool = true
}

enum BlueLightType: String {
    case emergencyPhone = "Emergency Phone"
    case securityStation = "Security Station"
    case safeZone = "Safe Zone"
    
    var icon: String {
        switch self {
        case .emergencyPhone: return "phone.circle.fill"
        case .securityStation: return "shield.checkered"
        case .safeZone: return "checkmark.shield.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .emergencyPhone: return .blue
        case .securityStation: return .green
        case .safeZone: return .purple
        }
    }
}

struct SafeWalkRequest: Identifiable, Codable {
    let id: UUID
    let pickupLatitude: Double
    let pickupLongitude: Double
    let destinationLatitude: Double
    let destinationLongitude: Double
    let requestTime: Date
    var status: SafeWalkStatus
    var estimatedArrival: Date?
    var escortName: String?
    
    var pickupCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: pickupLatitude, longitude: pickupLongitude)
    }
    
    var destinationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: destinationLatitude, longitude: destinationLongitude)
    }
    
    init(pickupLocation: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) {
        self.id = UUID()
        self.pickupLatitude = pickupLocation.latitude
        self.pickupLongitude = pickupLocation.longitude
        self.destinationLatitude = destination.latitude
        self.destinationLongitude = destination.longitude
        self.requestTime = Date()
        self.status = .pending
    }
}

enum SafeWalkStatus: String, Codable {
    case pending = "Pending"
    case accepted = "Accepted"
    case enRoute = "En Route"
    case arrived = "Arrived"
    case completed = "Completed"
    case cancelled = "Cancelled"
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .accepted: return .blue
        case .enRoute: return .green
        case .arrived: return .purple
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
}

// MARK: - SOS Alert
struct SOSAlert: Identifiable, Codable {
    let id: UUID
    let triggerTime: Date
    let locationLatitude: Double
    let locationLongitude: Double
    var isActive: Bool
    var notifiedContacts: [String]
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: locationLatitude, longitude: locationLongitude)
    }
    
    init(location: CLLocationCoordinate2D) {
        self.id = UUID()
        self.triggerTime = Date()
        self.locationLatitude = location.latitude
        self.locationLongitude = location.longitude
        self.isActive = true
        self.notifiedContacts = []
    }
}

// MARK: - Safety Manager
@Observable
class SafetyManager {
    // MARK: - Properties
    var emergencyContacts: [EmergencyContact] = []
    var blueLightLocations: [BlueLightLocation] = []
    var activeSafeWalkRequest: SafeWalkRequest?
    var activeSOSAlert: SOSAlert?
    
    var isSOSActive: Bool = false
    var sosCountdown: Int = 5
    var isCancellingCountdown: Bool = false
    
    // Campus security info
    let campusSecurityPhone = "1234567890"
    let campusSecurityName = "Campus Security"
    
    // Night mode (darker UI, well-lit paths)
    var isNightModeEnabled: Bool = false
    var wellLitPathsOnly: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let contactsKey = "emergency_contacts"
    
    // MARK: - Initialization
    init() {
        loadContacts()
        loadBlueLightLocations()
        checkNightMode()
    }
    
    // MARK: - Emergency Contacts
    private func loadContacts() {
        // Add default campus security
        var contacts: [EmergencyContact] = [
            EmergencyContact(
                name: "Campus Security",
                phone: campusSecurityPhone,
                relationship: "Campus",
                isEmergencyServices: true
            ),
            EmergencyContact(
                name: "Emergency Services",
                phone: "911",
                relationship: "Emergency",
                isEmergencyServices: true
            )
        ]
        
        // Load saved contacts
        if let data = userDefaults.data(forKey: contactsKey),
           let savedContacts = try? JSONDecoder().decode([EmergencyContact].self, from: data) {
            contacts.append(contentsOf: savedContacts.filter { !$0.isEmergencyServices })
        }
        
        emergencyContacts = contacts
    }
    
    func addContact(_ contact: EmergencyContact) {
        emergencyContacts.append(contact)
        savePersonalContacts()
    }
    
    func removeContact(_ contact: EmergencyContact) {
        guard !contact.isEmergencyServices else { return }
        emergencyContacts.removeAll { $0.id == contact.id }
        savePersonalContacts()
    }
    
    func updateContact(_ contact: EmergencyContact) {
        guard let index = emergencyContacts.firstIndex(where: { $0.id == contact.id }) else { return }
        emergencyContacts[index] = contact
        savePersonalContacts()
    }
    
    private func savePersonalContacts() {
        let personal = emergencyContacts.filter { !$0.isEmergencyServices }
        if let data = try? JSONEncoder().encode(personal) {
            userDefaults.set(data, forKey: contactsKey)
        }
    }
    
    // MARK: - Blue Light Locations
    private func loadBlueLightLocations() {
        // Sample blue light locations - replace with actual campus data
        blueLightLocations = [
            BlueLightLocation(
                name: "Main Library Entrance",
                coordinate: CLLocationCoordinate2D(latitude: 12.8231, longitude: 80.0443),
                type: .emergencyPhone
            ),
            BlueLightLocation(
                name: "Engineering Block",
                coordinate: CLLocationCoordinate2D(latitude: 12.8235, longitude: 80.0449),
                type: .emergencyPhone
            ),
            BlueLightLocation(
                name: "Campus Security Office",
                coordinate: CLLocationCoordinate2D(latitude: 12.8222, longitude: 80.0436),
                type: .securityStation
            ),
            BlueLightLocation(
                name: "Student Center",
                coordinate: CLLocationCoordinate2D(latitude: 12.8225, longitude: 80.0441),
                type: .safeZone
            ),
            BlueLightLocation(
                name: "Hostel Block 1",
                coordinate: CLLocationCoordinate2D(latitude: 12.8245, longitude: 80.0464),
                type: .emergencyPhone
            ),
            BlueLightLocation(
                name: "Sports Complex",
                coordinate: CLLocationCoordinate2D(latitude: 12.8240, longitude: 80.0459),
                type: .emergencyPhone
            ),
            BlueLightLocation(
                name: "Parking Lot A",
                coordinate: CLLocationCoordinate2D(latitude: 12.8218, longitude: 80.0431),
                type: .emergencyPhone
            )
        ]
    }
    
    func nearestBlueLight(from location: CLLocationCoordinate2D) -> BlueLightLocation? {
        let userLoc = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        return blueLightLocations
            .filter { $0.isOperational }
            .min { loc1, loc2 in
                let dist1 = CLLocation(latitude: loc1.coordinate.latitude, longitude: loc1.coordinate.longitude).distance(from: userLoc)
                let dist2 = CLLocation(latitude: loc2.coordinate.latitude, longitude: loc2.coordinate.longitude).distance(from: userLoc)
                return dist1 < dist2
            }
    }
    
    func distanceToNearestBlueLight(from location: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let nearest = nearestBlueLight(from: location) else { return nil }
        let userLoc = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let blueLoc = CLLocation(latitude: nearest.coordinate.latitude, longitude: nearest.coordinate.longitude)
        return userLoc.distance(from: blueLoc)
    }
    
    // MARK: - SOS Alert
    func triggerSOS(location: CLLocationCoordinate2D) {
        isSOSActive = true
        sosCountdown = 5
        
        // Start countdown
        startSOSCountdown(location: location)
    }
    
    private func startSOSCountdown(location: CLLocationCoordinate2D) {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if self.isCancellingCountdown {
                timer.invalidate()
                self.cancelSOS()
                return
            }
            
            self.sosCountdown -= 1
            
            if self.sosCountdown <= 0 {
                timer.invalidate()
                self.sendSOSAlert(location: location)
            }
        }
    }
    
    func cancelSOS() {
        isCancellingCountdown = true
        isSOSActive = false
        sosCountdown = 5
        activeSOSAlert = nil
        
        // Reset for next use
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isCancellingCountdown = false
        }
    }
    
    private func sendSOSAlert(location: CLLocationCoordinate2D) {
        // Create alert
        var alert = SOSAlert(location: location)
        
        // In a real app, this would:
        // 1. Send SMS to emergency contacts
        // 2. Call campus security
        // 3. Share live location
        // 4. Trigger loud alarm sound
        
        // For now, we'll just log and store
        for contact in emergencyContacts {
            alert.notifiedContacts.append(contact.name)
            print("SOS: Notifying \(contact.name) at \(contact.phone)")
        }
        
        activeSOSAlert = alert
        
        // Trigger haptic feedback
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        #endif
    }
    
    func deactivateSOS() {
        activeSOSAlert?.isActive = false
        isSOSActive = false
        activeSOSAlert = nil
    }
    
    // MARK: - Safe Walk Request
    func requestSafeWalk(from pickup: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        let request = SafeWalkRequest(pickupLocation: pickup, destination: destination)
        activeSafeWalkRequest = request
        
        // In a real app, this would send to campus security
        // Simulate acceptance after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.simulateSafeWalkProgress()
        }
    }
    
    private func simulateSafeWalkProgress() {
        guard var request = activeSafeWalkRequest else { return }
        
        request.status = .accepted
        request.escortName = "Security Officer John"
        request.estimatedArrival = Date().addingTimeInterval(300) // 5 minutes
        activeSafeWalkRequest = request
        
        // Simulate en route after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.updateSafeWalkStatus(.enRoute)
        }
    }
    
    func updateSafeWalkStatus(_ status: SafeWalkStatus) {
        activeSafeWalkRequest?.status = status
    }
    
    func cancelSafeWalkRequest() {
        activeSafeWalkRequest?.status = .cancelled
        activeSafeWalkRequest = nil
    }
    
    // MARK: - Night Mode
    private func checkNightMode() {
        let hour = Calendar.current.component(.hour, from: Date())
        // Auto-enable between 7 PM and 6 AM
        isNightModeEnabled = hour >= 19 || hour < 6
    }
    
    func toggleNightMode() {
        isNightModeEnabled.toggle()
    }
    
    // MARK: - Phone Calls
    func callContact(_ contact: EmergencyContact) {
        let cleanPhone = contact.phone.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        if let url = URL(string: "tel://\(cleanPhone)") {
            #if os(iOS)
            UIApplication.shared.open(url)
            #endif
        }
    }
    
    func callCampusSecurity() {
        if let url = URL(string: "tel://\(campusSecurityPhone)") {
            #if os(iOS)
            UIApplication.shared.open(url)
            #endif
        }
    }
    
    // MARK: - Share Location
    func shareLocationMessage(location: CLLocationCoordinate2D) -> String {
        let mapsURL = "https://maps.apple.com/?ll=\(location.latitude),\(location.longitude)"
        return "🆘 EMERGENCY: I need help! My location: \(mapsURL)"
    }
}
