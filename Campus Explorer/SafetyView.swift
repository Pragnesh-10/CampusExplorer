//
//  SafetyView.swift
//  Campus Explorer
//
//  Emergency and safety features UI
//

import SwiftUI
import MapKit

struct SafetyView: View {
    @Bindable var safetyManager: SafetyManager
    @ObservedObject var locationManager: LocationManager
    
    @State private var showingAddContact = false
    @State private var showingSafeWalk = false
    @State private var showingSOSConfirm = false
    @State private var selectedContactForEdit: EmergencyContact?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // SOS Button
                    sosSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Safe Walk Request
                    if safetyManager.activeSafeWalkRequest != nil {
                        activeSafeWalkCard
                    }
                    
                    // Blue Lights Map
                    blueLightsSection
                    
                    // Emergency Contacts
                    emergencyContactsSection
                    
                    // Night Mode
                    nightModeSection
                }
                .padding()
            }
            .navigationTitle("Safety")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddContact = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddContact) {
                AddContactSheet(safetyManager: safetyManager)
            }
            .sheet(item: $selectedContactForEdit) { contact in
                EditContactSheet(safetyManager: safetyManager, contact: contact)
            }
            .sheet(isPresented: $showingSafeWalk) {
                SafeWalkRequestSheet(safetyManager: safetyManager, locationManager: locationManager)
            }
            .fullScreenCover(isPresented: $safetyManager.isSOSActive) {
                SOSActiveView(safetyManager: safetyManager, locationManager: locationManager)
            }
        }
    }
    
    // MARK: - SOS Section
    private var sosSection: some View {
        VStack(spacing: 16) {
            Button {
                if let location = locationManager.currentLocation?.coordinate {
                    safetyManager.triggerSOS(location: location)
                }
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: "sos.circle.fill")
                        .font(.system(size: 60))
                    
                    Text("SOS Emergency")
                        .font(.title2.bold())
                    
                    Text("Hold to alert contacts & security")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(
                    LinearGradient(
                        colors: [.red, .red.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .red.opacity(0.4), radius: 10, y: 5)
            }
            
            Text("Alerts all emergency contacts and campus security with your location")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Call Security",
                    icon: "phone.fill",
                    color: .blue
                ) {
                    safetyManager.callCampusSecurity()
                }
                
                QuickActionButton(
                    title: "Safe Walk",
                    icon: "figure.walk",
                    color: .green
                ) {
                    showingSafeWalk = true
                }
                
                QuickActionButton(
                    title: "Blue Lights",
                    icon: "light.beacon.max.fill",
                    color: .purple
                ) {
                    // Scroll to blue lights section
                }
            }
        }
    }
    
    // MARK: - Active Safe Walk Card
    private var activeSafeWalkCard: some View {
        VStack(spacing: 12) {
            if let request = safetyManager.activeSafeWalkRequest {
                HStack {
                    Image(systemName: "figure.walk.diamond.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Safe Walk Request")
                            .font(.headline)
                        
                        HStack {
                            Text(request.status.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(request.status.color.opacity(0.2))
                                .foregroundStyle(request.status.color)
                                .clipShape(Capsule())
                            
                            if let escort = request.escortName {
                                Text("• \(escort)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        safetyManager.cancelSafeWalkRequest()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let eta = request.estimatedArrival {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(.secondary)
                        Text("ETA: \(eta, style: .time)")
                            .font(.subheadline)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Blue Lights Section
    private var blueLightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Blue Light Locations")
                    .font(.headline)
                
                Spacer()
                
                if let distance = safetyManager.distanceToNearestBlueLight(
                    from: locationManager.currentLocation?.coordinate ?? CLLocationCoordinate2D()
                ) {
                    Text("Nearest: \(Int(distance))m")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Mini map showing blue lights
            Map {
                UserAnnotation()
                
                ForEach(safetyManager.blueLightLocations) { location in
                    Annotation(location.name, coordinate: location.coordinate) {
                        Image(systemName: location.type.icon)
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(location.type.color)
                            .clipShape(Circle())
                    }
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Blue light legend
            HStack(spacing: 16) {
                ForEach([BlueLightType.emergencyPhone, .securityStation, .safeZone], id: \.self) { type in
                    HStack(spacing: 4) {
                        Image(systemName: type.icon)
                            .font(.caption)
                            .foregroundStyle(type.color)
                        Text(type.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Emergency Contacts Section
    private var emergencyContactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Emergency Contacts")
                .font(.headline)
            
            ForEach(safetyManager.emergencyContacts) { contact in
                EmergencyContactRow(
                    contact: contact,
                    onCall: { safetyManager.callContact(contact) },
                    onEdit: { selectedContactForEdit = contact },
                    onDelete: { safetyManager.removeContact(contact) }
                )
            }
            
            Button {
                showingAddContact = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Contact")
                }
                .foregroundStyle(.blue)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Night Mode Section
    private var nightModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Night Mode Settings")
                .font(.headline)
            
            Toggle(isOn: $safetyManager.isNightModeEnabled) {
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundStyle(.indigo)
                    VStack(alignment: .leading) {
                        Text("Night Mode")
                        Text("Enhanced safety features after dark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Toggle(isOn: $safetyManager.wellLitPathsOnly) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    VStack(alignment: .leading) {
                        Text("Well-Lit Paths Only")
                        Text("Navigation prioritizes lit walkways")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Supporting Views
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct EmergencyContactRow: View {
    let contact: EmergencyContact
    let onCall: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: contact.isEmergencyServices ? "shield.fill" : "person.circle.fill")
                .font(.title2)
                .foregroundStyle(contact.isEmergencyServices ? .red : .blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.body.weight(.medium))
                Text(contact.relationship)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if !contact.isEmergencyServices {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            
            Button(action: onCall) {
                Image(systemName: "phone.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.green)
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .swipeActions(edge: .trailing) {
            if !contact.isEmergencyServices {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - SOS Active View
struct SOSActiveView: View {
    @Bindable var safetyManager: SafetyManager
    @ObservedObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.red.ignoresSafeArea()
            
            VStack(spacing: 30) {
                if safetyManager.sosCountdown > 0 {
                    // Countdown
                    VStack(spacing: 20) {
                        Text("SOS ALERT")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                        
                        Text("\(safetyManager.sosCountdown)")
                            .font(.system(size: 120, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("Sending alert in \(safetyManager.sosCountdown) seconds")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Button {
                            safetyManager.cancelSOS()
                            dismiss()
                        } label: {
                            Text("CANCEL")
                                .font(.title2.bold())
                                .foregroundStyle(.red)
                                .padding(.horizontal, 60)
                                .padding(.vertical, 20)
                                .background(Color.white)
                                .clipShape(Capsule())
                        }
                        .padding(.top, 30)
                    }
                } else if let alert = safetyManager.activeSOSAlert {
                    // Alert Sent
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.white)
                        
                        Text("ALERT SENT")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                        
                        Text("Help is on the way")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.8))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(alert.notifiedContacts, id: \.self) { contact in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Notified: \(contact)")
                                }
                                .foregroundStyle(.white)
                            }
                        }
                        .padding()
                        
                        Button {
                            safetyManager.deactivateSOS()
                            dismiss()
                        } label: {
                            Text("I'm Safe - Cancel Alert")
                                .font(.headline)
                                .foregroundStyle(.red)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .clipShape(Capsule())
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Add Contact Sheet
struct AddContactSheet: View {
    @Bindable var safetyManager: SafetyManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var phone = ""
    @State private var relationship = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Relationship", text: $relationship)
                }
                
                Section {
                    Text("This contact will be notified in case of emergency with your location.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let contact = EmergencyContact(
                            name: name,
                            phone: phone,
                            relationship: relationship
                        )
                        safetyManager.addContact(contact)
                        dismiss()
                    }
                    .disabled(name.isEmpty || phone.isEmpty)
                }
            }
        }
    }
}

// MARK: - Edit Contact Sheet
struct EditContactSheet: View {
    @Bindable var safetyManager: SafetyManager
    let contact: EmergencyContact
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var phone: String
    @State private var relationship: String
    
    init(safetyManager: SafetyManager, contact: EmergencyContact) {
        self.safetyManager = safetyManager
        self.contact = contact
        _name = State(initialValue: contact.name)
        _phone = State(initialValue: contact.phone)
        _relationship = State(initialValue: contact.relationship)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Relationship", text: $relationship)
                }
            }
            .navigationTitle("Edit Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        var updated = contact
                        updated.name = name
                        updated.phone = phone
                        updated.relationship = relationship
                        safetyManager.updateContact(updated)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Safe Walk Request Sheet
struct SafeWalkRequestSheet: View {
    @Bindable var safetyManager: SafetyManager
    @ObservedObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var destinationSearch = ""
    @State private var selectedDestination: CLLocationCoordinate2D?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Request a campus security escort to walk with you to your destination.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                // Pickup location (current)
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.blue)
                    Text("Current Location")
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Destination
                HStack {
                    Image(systemName: "flag.fill")
                        .foregroundStyle(.red)
                    TextField("Enter destination", text: $destinationSearch)
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Spacer()
                
                // Request Button
                Button {
                    if let pickup = locationManager.currentLocation?.coordinate {
                        // Use a sample destination for demo
                        let destination = CLLocationCoordinate2D(latitude: 12.8231, longitude: 80.0444)
                        safetyManager.requestSafeWalk(from: pickup, to: destination)
                        dismiss()
                    }
                } label: {
                    HStack {
                        Image(systemName: "figure.walk")
                        Text("Request Safe Walk")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                Text("A security officer will meet you at your location and escort you to your destination.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("Safe Walk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SafetyView(
        safetyManager: SafetyManager(),
        locationManager: LocationManager()
    )
}
