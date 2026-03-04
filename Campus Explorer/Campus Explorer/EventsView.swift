//
//  EventsView.swift
//  Campus Explorer
//
//  Display campus events with filtering and search
//

import SwiftUI

struct EventsView: View {
    @Bindable var eventsManager: EventsManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Category Filter
                categoryFilter
                
                // Events List
                List {
                    if eventsManager.filteredEvents.isEmpty {
                        ContentUnavailableView(
                            "No Events Found",
                            systemImage: "calendar.badge.exclamationmark",
                            description: Text("Try adjusting your filters or search.")
                        )
                    } else {
                        ForEach(eventsManager.filteredEvents) { event in
                            EventRow(event: event) {
                                eventsManager.toggleAttendance(for: event)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Events")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Create event (future feature)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search events...", text: $eventsManager.searchText)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "All",
                    isSelected: eventsManager.selectedCategory == nil,
                    action: { eventsManager.selectedCategory = nil }
                )
                
                ForEach(EventCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.rawValue,
                        isSelected: eventsManager.selectedCategory == category,
                        action: { eventsManager.selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? .blue : Color(.systemGray6))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

struct EventRow: View {
    let event: CampusEvent
    let toggleAttendance: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image Placeholder
            ZStack {
                Rectangle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Image(systemName: event.category.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.headline)
                
                HStack {
                    Image(systemName: "calendar")
                    Text(event.date.formatted(date: .abbreviated, time: .shortened))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                    Text(event.locationName)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                Text(event.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                // Footer
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                        Text("\(event.attendeesCount) attending")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button(action: toggleAttendance) {
                        Text(event.isAttending ? "Going" : "Join")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(event.isAttending ? .green : .blue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    EventsView(eventsManager: EventsManager())
}
