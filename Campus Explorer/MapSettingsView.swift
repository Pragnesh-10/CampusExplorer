//
//  MapSettingsView.swift
//  Campus Explorer
//
//  Map customization and settings
//

import SwiftUI
import MapKit
import Observation

// MARK: - Map Style
enum MapStyleOption: String, CaseIterable {
    case standard = "Standard"
    case satellite = "Satellite"
    case hybrid = "Hybrid"
    
    var mapStyle: MapStyle {
        switch self {
        case .standard: return .standard
        case .satellite: return .imagery
        case .hybrid: return .hybrid
        }
    }
    
    var iconName: String {
        switch self {
        case .standard: return "map"
        case .satellite: return "globe.americas.fill"
        case .hybrid: return "square.stack.3d.up.fill"
        }
    }
}

// MARK: - Map Settings Manager
@Observable
@MainActor
class MapSettingsManager {
    var selectedMapStyle: MapStyleOption = .standard
    var showTraffic: Bool = false
    var showPOIs: Bool = true
    var showFriendLocations: Bool = true
    var showHeatMap: Bool = false
    var showFogOfWar: Bool = false
    var showPathHistory: Bool = true
    var autoFollowUser: Bool = true
    var mapPitch: Double = 0
    var showCompass: Bool = true
    var showScale: Bool = true
    
    // POI Filter
    var enabledPOICategories: Set<POICategory> = Set(POICategory.allCases)
    
    // Appearance
    var pathColor: Color = .blue
    var pathWidth: Double = 3.0
    var friendMarkerSize: Double = 30.0
    
    init() {
        loadSettings()
    }
    
    func togglePOICategory(_ category: POICategory) {
        if enabledPOICategories.contains(category) {
            enabledPOICategories.remove(category)
        } else {
            enabledPOICategories.insert(category)
        }
        saveSettings()
    }
    
    func resetToDefaults() {
        selectedMapStyle = .standard
        showTraffic = false
        showPOIs = true
        showFriendLocations = true
        showHeatMap = false
        showFogOfWar = false
        showPathHistory = true
        autoFollowUser = true
        mapPitch = 0
        showCompass = true
        showScale = true
        enabledPOICategories = Set(POICategory.allCases)
        pathColor = .blue
        pathWidth = 3.0
        friendMarkerSize = 30.0
        saveSettings()
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(selectedMapStyle.rawValue, forKey: "mapStyle")
        UserDefaults.standard.set(showTraffic, forKey: "showTraffic")
        UserDefaults.standard.set(showPOIs, forKey: "showPOIs")
        UserDefaults.standard.set(showFriendLocations, forKey: "showFriendLocations")
        UserDefaults.standard.set(showHeatMap, forKey: "showHeatMap")
        UserDefaults.standard.set(showFogOfWar, forKey: "showFogOfWar")
        UserDefaults.standard.set(showPathHistory, forKey: "showPathHistory")
        UserDefaults.standard.set(autoFollowUser, forKey: "autoFollowUser")
        UserDefaults.standard.set(mapPitch, forKey: "mapPitch")
        UserDefaults.standard.set(showCompass, forKey: "showCompass")
        UserDefaults.standard.set(showScale, forKey: "showScale")
        UserDefaults.standard.set(pathWidth, forKey: "pathWidth")
        UserDefaults.standard.set(friendMarkerSize, forKey: "friendMarkerSize")
        
        // Save POI categories
        let categoryStrings = enabledPOICategories.map { $0.rawValue }
        UserDefaults.standard.set(categoryStrings, forKey: "enabledPOICategories")
    }
    
    private func loadSettings() {
        if let styleRaw = UserDefaults.standard.string(forKey: "mapStyle"),
           let style = MapStyleOption(rawValue: styleRaw) {
            selectedMapStyle = style
        }
        
        showTraffic = UserDefaults.standard.bool(forKey: "showTraffic")
        showPOIs = UserDefaults.standard.object(forKey: "showPOIs") as? Bool ?? true
        showFriendLocations = UserDefaults.standard.object(forKey: "showFriendLocations") as? Bool ?? true
        showHeatMap = UserDefaults.standard.bool(forKey: "showHeatMap")
        showFogOfWar = UserDefaults.standard.bool(forKey: "showFogOfWar")
        showPathHistory = UserDefaults.standard.object(forKey: "showPathHistory") as? Bool ?? true
        autoFollowUser = UserDefaults.standard.object(forKey: "autoFollowUser") as? Bool ?? true
        mapPitch = UserDefaults.standard.double(forKey: "mapPitch")
        showCompass = UserDefaults.standard.object(forKey: "showCompass") as? Bool ?? true
        showScale = UserDefaults.standard.object(forKey: "showScale") as? Bool ?? true
        pathWidth = UserDefaults.standard.object(forKey: "pathWidth") as? Double ?? 3.0
        friendMarkerSize = UserDefaults.standard.object(forKey: "friendMarkerSize") as? Double ?? 30.0
        
        // Load POI categories
        if let categoryStrings = UserDefaults.standard.array(forKey: "enabledPOICategories") as? [String] {
            enabledPOICategories = Set(categoryStrings.compactMap { POICategory(rawValue: $0) })
        }
    }
}

// MARK: - Map Settings View
struct MapSettingsView: View {
    @Bindable var mapSettings: MapSettingsManager
    @Bindable var heatMapManager: HeatMapManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Map Style Section
                Section("Map Style") {
                    ForEach(MapStyleOption.allCases, id: \.self) { style in
                        Button {
                            mapSettings.selectedMapStyle = style
                        } label: {
                            HStack {
                                Image(systemName: style.iconName)
                                    .frame(width: 30)
                                Text(style.rawValue)
                                Spacer()
                                if mapSettings.selectedMapStyle == style {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
                
                // Map Layers Section
                Section("Map Layers") {
                    Toggle("Show POIs", isOn: $mapSettings.showPOIs)
                    Toggle("Show Friend Locations", isOn: $mapSettings.showFriendLocations)
                    Toggle("Show Path History", isOn: $mapSettings.showPathHistory)
                    Toggle("Show Heat Map", isOn: $mapSettings.showHeatMap)
                    Toggle("Fog of War Effect", isOn: $mapSettings.showFogOfWar)
                }
                
                // POI Filter Section
                Section("POI Categories") {
                    ForEach(POICategory.allCases, id: \.self) { category in
                        Button {
                            mapSettings.togglePOICategory(category)
                        } label: {
                            HStack {
                                Image(systemName: category.iconName)
                                    .foregroundStyle(category.color)
                                    .frame(width: 30)
                                Text(category.rawValue)
                                Spacer()
                                if mapSettings.enabledPOICategories.contains(category) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
                
                // Map Controls Section
                Section("Map Controls") {
                    Toggle("Auto-Follow User", isOn: $mapSettings.autoFollowUser)
                    Toggle("Show Compass", isOn: $mapSettings.showCompass)
                    Toggle("Show Scale", isOn: $mapSettings.showScale)
                    
                    VStack(alignment: .leading) {
                        Text("Map Tilt: \(Int(mapSettings.mapPitch))°")
                        Slider(value: $mapSettings.mapPitch, in: 0...60)
                    }
                }
                
                // Appearance Section
                Section("Appearance") {
                    ColorPicker("Path Color", selection: $mapSettings.pathColor)
                    
                    VStack(alignment: .leading) {
                        Text("Path Width: \(Int(mapSettings.pathWidth))")
                        Slider(value: $mapSettings.pathWidth, in: 1...10)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Friend Marker Size: \(Int(mapSettings.friendMarkerSize))")
                        Slider(value: $mapSettings.friendMarkerSize, in: 20...50)
                    }
                }
                
                // Exploration Stats
                Section("Exploration") {
                    HStack {
                        Text("Area Explored")
                        Spacer()
                        Text(String(format: "%.1f%%", heatMapManager.explorationPercentage))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("POIs Visited")
                        Spacer()
                        Text("\(heatMapManager.visitedPOIsCount)/\(heatMapManager.pointsOfInterest.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    Button("Reset Exploration Data", role: .destructive) {
                        heatMapManager.resetExploration()
                    }
                }
                
                // Reset Section
                Section {
                    Button("Reset to Defaults") {
                        mapSettings.resetToDefaults()
                    }
                }
            }
            .navigationTitle("Map Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - POI Detail View
struct POIDetailView: View {
    let poi: PointOfInterest
    @Bindable var heatMapManager: HeatMapManager
    @Environment(\.dismiss) private var dismiss
    @State private var notes: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Image(systemName: poi.category.iconName)
                            .font(.largeTitle)
                            .foregroundStyle(poi.category.color)
                            .frame(width: 60, height: 60)
                            .background(poi.category.color.opacity(0.2))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text(poi.name)
                                .font(.title2)
                                .bold()
                            Text(poi.category.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section("Visit Info") {
                    HStack {
                        Text("Status")
                        Spacer()
                        if poi.isVisited {
                            Label("Visited", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Label("Not Visited", systemImage: "circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if poi.isVisited {
                        HStack {
                            Text("Visit Count")
                            Spacer()
                            Text("\(poi.visitCount)")
                                .foregroundStyle(.secondary)
                        }
                        
                        if let lastVisit = poi.lastVisited {
                            HStack {
                                Text("Last Visited")
                                Spacer()
                                Text(lastVisit, style: .relative)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                Section("Location") {
                    HStack {
                        Text("Latitude")
                        Spacer()
                        Text(String(format: "%.4f", poi.coordinate.latitude))
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Longitude")
                        Spacer()
                        Text(String(format: "%.4f", poi.coordinate.longitude))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                if poi.category == .custom {
                    Section {
                        Button("Delete POI", role: .destructive) {
                            heatMapManager.removePOI(poi)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Point of Interest")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                notes = poi.notes
            }
        }
    }
}

// MARK: - Add POI View
struct AddPOIView: View {
    @Bindable var heatMapManager: HeatMapManager
    let coordinate: CLLocationCoordinate2D
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var selectedCategory: POICategory = .custom
    @State private var notes: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("POI Details") {
                    TextField("Name", text: $name)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(POICategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.iconName)
                                .tag(category)
                        }
                    }
                }
                
                Section("Location") {
                    HStack {
                        Text("Latitude")
                        Spacer()
                        Text(String(format: "%.4f", coordinate.latitude))
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Longitude")
                        Spacer()
                        Text(String(format: "%.4f", coordinate.longitude))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button("Add POI") {
                        heatMapManager.addCustomPOI(
                            name: name,
                            category: selectedCategory,
                            coordinate: coordinate,
                            notes: notes
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .navigationTitle("Add POI")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MapSettingsView(
        mapSettings: MapSettingsManager(),
        heatMapManager: HeatMapManager()
    )
}
