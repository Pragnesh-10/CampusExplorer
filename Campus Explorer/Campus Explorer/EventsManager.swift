//
//  EventsManager.swift
//  Campus Explorer
//
//  Manages campus events and user attendance
//

import Foundation
import Observation
import MapKit

enum EventCategory: String, Codable, CaseIterable {
    case academic = "Academic"
    case social = "Social"
    case sports = "Sports"
    case arts = "Arts & Culture"
    case career = "Career"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .academic: return "book.fill"
        case .social: return "person.2.fill"
        case .sports: return "sportscourt.fill"
        case .arts: return "paintpalette.fill"
        case .career: return "briefcase.fill"
        case .other: return "calendar"
        }
    }
}

struct CampusEvent: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let date: Date
    let endDate: Date
    let locationName: String
    let coordinate: CLLocationCoordinate2D? // Optional for now
    let category: EventCategory
    let imageName: String?
    var attendeesCount: Int
    var isAttending: Bool
    
    // Custom coding keys to skip coordinate since it's not Codable easily without wrapper
    enum CodingKeys: String, CodingKey {
        case id, title, description, date, endDate, locationName, category, imageName, attendeesCount, isAttending
    }
    
    init(id: UUID = UUID(), title: String, description: String, date: Date, endDate: Date, locationName: String, coordinate: CLLocationCoordinate2D? = nil, category: EventCategory, imageName: String? = nil, attendeesCount: Int = 0, isAttending: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.date = date
        self.endDate = endDate
        self.locationName = locationName
        self.coordinate = coordinate
        self.category = category
        self.imageName = imageName
        self.attendeesCount = attendeesCount
        self.isAttending = isAttending
    }
    
    // Manual decoding to handle optional coordinate skipping if needed, but for now we just skip coordinate in codable
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        date = try container.decode(Date.self, forKey: .date)
        endDate = try container.decode(Date.self, forKey: .endDate)
        locationName = try container.decode(String.self, forKey: .locationName)
        category = try container.decode(EventCategory.self, forKey: .category)
        imageName = try container.decodeIfPresent(String.self, forKey: .imageName)
        attendeesCount = try container.decode(Int.self, forKey: .attendeesCount)
        isAttending = try container.decode(Bool.self, forKey: .isAttending)
        coordinate = nil // Coordinate not persisted in simple JSON
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(date, forKey: .date)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(locationName, forKey: .locationName)
        try container.encode(category, forKey: .category)
        try container.encode(imageName, forKey: .imageName)
        try container.encode(attendeesCount, forKey: .attendeesCount)
        try container.encode(isAttending, forKey: .isAttending)
    }
}

@Observable
class EventsManager {
    var events: [CampusEvent] = []
    var searchText = ""
    var selectedCategory: EventCategory?
    
    var filteredEvents: [CampusEvent] {
        events.filter { event in
            let matchesSearch = searchText.isEmpty || event.title.localizedCaseInsensitiveContains(searchText) || event.description.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || event.category == selectedCategory
            return matchesSearch && matchesCategory
        }
        .sorted { $0.date < $1.date }
    }
    
    private let userDefaults = UserDefaults.standard
    private let eventsKey = "campus_events"
    
    init() {
        loadEvents()
        if events.isEmpty {
            createSampleEvents()
        }
    }
    
    func toggleAttendance(for event: CampusEvent) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index].isAttending.toggle()
            if events[index].isAttending {
                events[index].attendeesCount += 1
            } else {
                events[index].attendeesCount -= 1
            }
            saveEvents()
        }
    }
    
    private func loadEvents() {
        if let data = userDefaults.data(forKey: eventsKey),
           let savedEvents = try? JSONDecoder().decode([CampusEvent].self, from: data) {
            events = savedEvents
        }
    }
    
    private func saveEvents() {
        if let data = try? JSONEncoder().encode(events) {
            userDefaults.set(data, forKey: eventsKey)
        }
    }
    
    private func createSampleEvents() {
        let today = Date()
        let calendar = Calendar.current
        
        func date(daysFromNow: Int, hour: Int) -> Date {
            let day = calendar.date(byAdding: .day, value: daysFromNow, to: today)!
            return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
        }
        
        events = [
            CampusEvent(
                title: "Freshman Welcome Mixer",
                description: "Meet your fellow students and enjoy free food and music! Open to all years.",
                date: date(daysFromNow: 1, hour: 18),
                endDate: date(daysFromNow: 1, hour: 21),
                locationName: "Student Center Plaza",
                category: .social,
                attendeesCount: 142,
                isAttending: false
            ),
            CampusEvent(
                title: "Career Fair: Tech & Engineering",
                description: "Network with top tech companies and startups. Bring your resume!",
                date: date(daysFromNow: 2, hour: 10),
                endDate: date(daysFromNow: 2, hour: 16),
                locationName: "University Gym",
                category: .career,
                attendeesCount: 350,
                isAttending: false
            ),
            CampusEvent(
                title: "Varsity Basketball vs. State",
                description: "Cheer on our team in the biggest game of the season.",
                date: date(daysFromNow: 3, hour: 19),
                endDate: date(daysFromNow: 3, hour: 22),
                locationName: "Arena",
                category: .sports,
                attendeesCount: 800,
                isAttending: false
            ),
            CampusEvent(
                title: "Research Symposium",
                description: "Undergraduate research presentations from all departments.",
                date: date(daysFromNow: 4, hour: 13),
                endDate: date(daysFromNow: 4, hour: 17),
                locationName: "Library Auditorium",
                category: .academic,
                attendeesCount: 45,
                isAttending: false
            ),
            CampusEvent(
                title: "Outdoor Movie Night",
                description: "Showing 'Inception'. Bring blankets and snacks.",
                date: date(daysFromNow: 5, hour: 20),
                endDate: date(daysFromNow: 5, hour: 23),
                locationName: "Quad Lawn",
                category: .arts,
                attendeesCount: 90,
                isAttending: false
            )
        ]
        saveEvents()
    }
}
