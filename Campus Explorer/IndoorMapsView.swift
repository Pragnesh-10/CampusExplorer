//
//  IndoorMapsView.swift
//  Campus Explorer
//
//  Indoor maps UI for building navigation
//

import SwiftUI
import MapKit

// MARK: - Indoor Maps Main View
struct IndoorMapsView: View {
    @Bindable var indoorMapsManager: IndoorMapsManager
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $indoorMapsManager.searchQuery, placeholder: "Search rooms, buildings...")
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                if !indoorMapsManager.searchQuery.isEmpty {
                    // Search Results
                    SearchResultsView(indoorMapsManager: indoorMapsManager)
                } else {
                    // Tab Selection
                    Picker("View", selection: $selectedTab) {
                        Text("Buildings").tag(0)
                        Text("Favorites").tag(1)
                        Text("Recent").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    switch selectedTab {
                    case 0:
                        BuildingsListView(indoorMapsManager: indoorMapsManager)
                    case 1:
                        FavoriteRoomsView(indoorMapsManager: indoorMapsManager)
                    case 2:
                        RecentRoomsView(indoorMapsManager: indoorMapsManager)
                    default:
                        BuildingsListView(indoorMapsManager: indoorMapsManager)
                    }
                }
            }
            .navigationTitle("Indoor Maps")
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Search Results View
struct SearchResultsView: View {
    @Bindable var indoorMapsManager: IndoorMapsManager
    
    var body: some View {
        if indoorMapsManager.searchResults.isEmpty {
            ContentUnavailableView {
                Label("No Results", systemImage: "magnifyingglass")
            } description: {
                Text("No rooms found matching '\(indoorMapsManager.searchQuery)'")
            }
        } else {
            List(indoorMapsManager.searchResults) { room in
                NavigationLink {
                    if let building = indoorMapsManager.getBuildingForRoom(room.id) {
                        RoomDetailView(room: room, building: building, indoorMapsManager: indoorMapsManager)
                    }
                } label: {
                    RoomRowView(room: room, indoorMapsManager: indoorMapsManager)
                }
            }
        }
    }
}

// MARK: - Buildings List View
struct BuildingsListView: View {
    @Bindable var indoorMapsManager: IndoorMapsManager
    
    var buildingsByCategory: [BuildingCategory: [Building]] {
        Dictionary(grouping: indoorMapsManager.buildings, by: { $0.category })
    }
    
    var body: some View {
        List {
            ForEach(BuildingCategory.allCases, id: \.self) { category in
                if let buildings = buildingsByCategory[category], !buildings.isEmpty {
                    Section {
                        ForEach(buildings) { building in
                            NavigationLink {
                                BuildingDetailView(building: building, indoorMapsManager: indoorMapsManager)
                            } label: {
                                BuildingRowView(building: building)
                            }
                        }
                    } header: {
                        Label(category.rawValue, systemImage: category.iconName)
                    }
                }
            }
        }
    }
}

// MARK: - Building Row View
struct BuildingRowView: View {
    let building: Building
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(building.category.color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: building.category.iconName)
                    .font(.title3)
                    .foregroundStyle(building.category.color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(building.name)
                    .font(.headline)
                
                HStack {
                    Text(building.shortName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(Capsule())
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text("\(building.floors.count) floors")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if building.isOpen {
                Text("Open")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Text("Closed")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Building Detail View
struct BuildingDetailView: View {
    let building: Building
    @Bindable var indoorMapsManager: IndoorMapsManager
    @State private var selectedFloorIndex = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Building Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(building.category.color.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: building.category.iconName)
                                .font(.title)
                                .foregroundStyle(building.category.color)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(building.name)
                                .font(.title2)
                                .bold()
                            
                            HStack {
                                Text(building.shortName)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(building.category.color.opacity(0.2))
                                    .clipShape(Capsule())
                                
                                if building.isOpen {
                                    Label("Open", systemImage: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                } else {
                                    Label("Closed", systemImage: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }
                    
                    if let hours = building.openingHours {
                        Label(hours, systemImage: "clock")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(building.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Floor Selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Floors")
                        .font(.headline)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(building.floors.enumerated()), id: \.element.id) { index, floor in
                                Button {
                                    selectedFloorIndex = index
                                } label: {
                                    VStack(spacing: 4) {
                                        Text("F\(floor.number)")
                                            .font(.headline)
                                        Text(floor.name)
                                            .font(.caption2)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(selectedFloorIndex == index ? building.category.color : Color(.systemGray5))
                                    .foregroundStyle(selectedFloorIndex == index ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Floor Plan / Room List
                if !building.floors.isEmpty {
                    let floor = building.floors[selectedFloorIndex]
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(floor.name) - Rooms")
                                .font(.headline)
                            Spacer()
                            Text("\(floor.rooms.count) rooms")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Room Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(floor.rooms) { room in
                                NavigationLink {
                                    RoomDetailView(room: room, building: building, indoorMapsManager: indoorMapsManager)
                                } label: {
                                    RoomCardView(room: room, indoorMapsManager: indoorMapsManager)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(building.shortName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Room Card View
struct RoomCardView: View {
    let room: Room
    @Bindable var indoorMapsManager: IndoorMapsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: room.type.iconName)
                    .foregroundStyle(room.type.color)
                
                Spacer()
                
                if indoorMapsManager.isFavorite(room.id) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }
            }
            
            Text(room.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Text(room.number)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if let capacity = room.capacity {
                Label("\(capacity)", systemImage: "person.2")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .foregroundStyle(.primary)
    }
}

// MARK: - Room Row View
struct RoomRowView: View {
    let room: Room
    @Bindable var indoorMapsManager: IndoorMapsManager
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(room.type.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: room.type.iconName)
                    .foregroundStyle(room.type.color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(room.name)
                    .font(.headline)
                
                HStack {
                    Text(room.number)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text("Floor \(room.floor)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if indoorMapsManager.isFavorite(room.id) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
            }
        }
    }
}

// MARK: - Room Detail View
struct RoomDetailView: View {
    let room: Room
    let building: Building
    @Bindable var indoorMapsManager: IndoorMapsManager
    @State private var showNavigation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Room Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(room.type.color.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: room.type.iconName)
                                .font(.title)
                                .foregroundStyle(room.type.color)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(room.name)
                                .font(.title2)
                                .bold()
                            
                            HStack {
                                Text(room.number)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.2))
                                    .clipShape(Capsule())
                                
                                Text(room.type.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(room.type.color.opacity(0.2))
                                    .foregroundStyle(room.type.color)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            indoorMapsManager.toggleFavorite(room.id)
                        } label: {
                            Image(systemName: indoorMapsManager.isFavorite(room.id) ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundStyle(indoorMapsManager.isFavorite(room.id) ? .yellow : .gray)
                        }
                    }
                    
                    if let description = room.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Location Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Location")
                        .font(.headline)
                    
                    HStack {
                        Label(building.name, systemImage: "building.2")
                        Spacer()
                    }
                    .font(.subheadline)
                    
                    HStack {
                        Label("Floor \(room.floor)", systemImage: "stairs")
                        Spacer()
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Capacity & Amenities
                if room.capacity != nil || !room.amenities.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.headline)
                        
                        if let capacity = room.capacity {
                            HStack {
                                Label("Capacity", systemImage: "person.2")
                                Spacer()
                                Text("\(capacity) people")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                        }
                        
                        if !room.amenities.isEmpty {
                            Divider()
                            
                            Text("Amenities")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(room.amenities, id: \.self) { amenity in
                                    Text(amenity)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundStyle(.blue)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Navigate Button
                Button {
                    indoorMapsManager.startNavigation(to: room)
                    indoorMapsManager.markAsVisited(room.id)
                    showNavigation = true
                } label: {
                    Label("Navigate to Room", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(room.number)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showNavigation) {
            if let route = indoorMapsManager.currentRoute {
                NavigationRouteView(route: route, indoorMapsManager: indoorMapsManager)
            }
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var positions: [CGPoint] = []
        var height: CGFloat = 0
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            height = y + rowHeight
        }
    }
}

// MARK: - Navigation Route View
struct NavigationRouteView: View {
    let route: IndoorRoute
    @Bindable var indoorMapsManager: IndoorMapsManager
    @Environment(\.dismiss) private var dismiss
    @State private var currentStepIndex = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Route Summary
                HStack {
                    VStack(alignment: .leading) {
                        Text("To: \(route.endRoom.name)")
                            .font(.headline)
                        Text(route.building.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("\(Int(route.estimatedTime))s")
                            .font(.headline)
                        Text("\(Int(route.distance))m")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // Steps List
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(route.steps.enumerated()), id: \.element.id) { index, step in
                            NavigationStepRow(step: step, index: index, isCurrentStep: index == currentStepIndex, totalSteps: route.steps.count)
                                .onTapGesture {
                                    currentStepIndex = index
                                }
                        }
                    }
                    .padding()
                }
                
                // Navigation Controls
                HStack(spacing: 20) {
                    Button {
                        if currentStepIndex > 0 {
                            currentStepIndex -= 1
                        }
                    } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.largeTitle)
                    }
                    .disabled(currentStepIndex == 0)
                    
                    VStack {
                        Text("Step \(currentStepIndex + 1) of \(route.steps.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(route.steps[currentStepIndex].instruction)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button {
                        if currentStepIndex < route.steps.count - 1 {
                            currentStepIndex += 1
                        }
                    } label: {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.largeTitle)
                    }
                    .disabled(currentStepIndex == route.steps.count - 1)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("Navigation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        indoorMapsManager.stopNavigation()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Navigation Step Row
struct NavigationStepRow: View {
    let step: NavigationStep
    let index: Int
    let isCurrentStep: Bool
    let totalSteps: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step indicator
            VStack(spacing: 0) {
                Circle()
                    .fill(isCurrentStep ? Color.blue : (index < totalSteps - 1 ? Color.green : Color.green))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: step.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                    }
                
                if index < totalSteps - 1 {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2, height: 40)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(step.instruction)
                    .font(isCurrentStep ? .headline : .subheadline)
                    .foregroundStyle(isCurrentStep ? .primary : .secondary)
                
                if let floor = step.floor {
                    Text("Floor \(floor)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
            
            Spacer()
        }
    }
}

// MARK: - Favorite Rooms View
struct FavoriteRoomsView: View {
    @Bindable var indoorMapsManager: IndoorMapsManager
    
    var favoriteRoomsList: [(Building, Room)] {
        var results: [(Building, Room)] = []
        for roomId in indoorMapsManager.favoriteRooms {
            if let (building, _, room) = indoorMapsManager.findRoom(by: roomId) {
                results.append((building, room))
            }
        }
        return results
    }
    
    var body: some View {
        if favoriteRoomsList.isEmpty {
            ContentUnavailableView {
                Label("No Favorites", systemImage: "star")
            } description: {
                Text("Star rooms to add them to your favorites")
            }
        } else {
            List(favoriteRoomsList, id: \.1.id) { building, room in
                NavigationLink {
                    RoomDetailView(room: room, building: building, indoorMapsManager: indoorMapsManager)
                } label: {
                    VStack(alignment: .leading) {
                        RoomRowView(room: room, indoorMapsManager: indoorMapsManager)
                        Text(building.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Recent Rooms View
struct RecentRoomsView: View {
    @Bindable var indoorMapsManager: IndoorMapsManager
    
    var recentRoomsList: [(Building, Room)] {
        var results: [(Building, Room)] = []
        for roomId in indoorMapsManager.recentlyVisited {
            if let (building, _, room) = indoorMapsManager.findRoom(by: roomId) {
                results.append((building, room))
            }
        }
        return results
    }
    
    var body: some View {
        if recentRoomsList.isEmpty {
            ContentUnavailableView {
                Label("No Recent Visits", systemImage: "clock")
            } description: {
                Text("Rooms you navigate to will appear here")
            }
        } else {
            List(recentRoomsList, id: \.1.id) { building, room in
                NavigationLink {
                    RoomDetailView(room: room, building: building, indoorMapsManager: indoorMapsManager)
                } label: {
                    VStack(alignment: .leading) {
                        RoomRowView(room: room, indoorMapsManager: indoorMapsManager)
                        Text(building.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    IndoorMapsView(indoorMapsManager: IndoorMapsManager())
}
