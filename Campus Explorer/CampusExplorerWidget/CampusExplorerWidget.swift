//
//  CampusExplorerWidget.swift
//  CampusExplorerWidget
//
//  Created by Y N Pragnesh on 05/02/26.
//

import WidgetKit
import SwiftUI

// MARK: - Shared Data Access
struct WidgetData {
    let steps: Int
    let distance: Double
    let calories: Double
    let streak: Int
    let points: Int
    let exploration: Double
    let lastUpdated: Date
    
    static let placeholder = WidgetData(
        steps: 5432,
        distance: 2.5,
        calories: 217,
        streak: 7,
        points: 1250,
        exploration: 45.0,
        lastUpdated: Date()
    )
    
    static func load() -> WidgetData {
        let defaults = UserDefaults(suiteName: "group.campus.explorer") ?? UserDefaults.standard
        return WidgetData(
            steps: defaults.integer(forKey: "widget_steps"),
            distance: defaults.double(forKey: "widget_distance"),
            calories: defaults.double(forKey: "widget_calories"),
            streak: defaults.integer(forKey: "widget_streak"),
            points: defaults.integer(forKey: "widget_points"),
            exploration: defaults.double(forKey: "widget_exploration"),
            lastUpdated: defaults.object(forKey: "widget_lastUpdated") as? Date ?? Date()
        )
    }
}

// MARK: - Timeline Provider
struct CampusExplorerProvider: TimelineProvider {
    func placeholder(in context: Context) -> CampusExplorerEntry {
        CampusExplorerEntry(date: Date(), data: .placeholder)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (CampusExplorerEntry) -> Void) {
        let entry = CampusExplorerEntry(date: Date(), data: WidgetData.load())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<CampusExplorerEntry>) -> Void) {
        let data = WidgetData.load()
        let entry = CampusExplorerEntry(date: Date(), data: data)
        
        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry
struct CampusExplorerEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Small Widget View
struct SmallWidgetView: View {
    let entry: CampusExplorerEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "figure.walk")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Spacer()
                Text("Today")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("\(entry.data.steps)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text("steps")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: geo.size.width * min(Double(entry.data.steps) / 10000.0, 1.0), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding()
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    let entry: CampusExplorerEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Steps section
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundStyle(.blue)
                    Text("Steps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text("\(entry.data.steps)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                
                Text("of 10,000")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            // Stats grid
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    StatItem(icon: "flame.fill", value: "\(Int(entry.data.calories))", label: "kcal", color: .orange)
                    StatItem(icon: "map.fill", value: String(format: "%.1f", entry.data.distance / 1000), label: "km", color: .green)
                }
                HStack(spacing: 16) {
                    StatItem(icon: "flame.circle.fill", value: "\(entry.data.streak)", label: "streak", color: .red)
                    StatItem(icon: "star.fill", value: "\(entry.data.points)", label: "pts", color: .yellow)
                }
            }
        }
        .padding()
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 50, alignment: .leading)
    }
}

// MARK: - Large Widget View
struct LargeWidgetView: View {
    let entry: CampusExplorerEntry
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Campus Explorer")
                        .font(.headline)
                    Text("Today's Progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "map.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            
            // Main stats
            HStack(spacing: 20) {
                LargeStatCard(icon: "figure.walk", value: "\(entry.data.steps)", label: "Steps", color: .blue, progress: Double(entry.data.steps) / 10000.0)
                LargeStatCard(icon: "flame.fill", value: "\(Int(entry.data.calories))", label: "Calories", color: .orange, progress: entry.data.calories / 500.0)
            }
            
            HStack(spacing: 20) {
                LargeStatCard(icon: "map.fill", value: String(format: "%.2f km", entry.data.distance / 1000), label: "Distance", color: .green, progress: (entry.data.distance / 1000) / 5.0)
                LargeStatCard(icon: "percent", value: String(format: "%.0f%%", entry.data.exploration), label: "Explored", color: .purple, progress: entry.data.exploration / 100.0)
            }
            
            // Streak
            HStack {
                Image(systemName: "flame.circle.fill")
                    .foregroundStyle(.red)
                Text("\(entry.data.streak) day streak")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(entry.data.points) points")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
    }
}

struct LargeStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * min(progress, 1.0), height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(10)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Widget Configuration
@available(iOS 17.0, *)
struct CampusExplorerWidget: Widget {
    let kind: String = "CampusExplorerWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CampusExplorerProvider()) { entry in
            Group {
                switch WidgetFamily.systemSmall {
                default:
                    SmallWidgetView(entry: entry)
                }
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Steps Tracker")
        .description("Track your daily steps and progress.")
        .supportedFamilies([.systemSmall])
    }
}

@available(iOS 17.0, *)
struct CampusExplorerMediumWidget: Widget {
    let kind: String = "CampusExplorerMediumWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CampusExplorerProvider()) { entry in
            MediumWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Campus Stats")
        .description("View your steps, calories, and streak.")
        .supportedFamilies([.systemMedium])
    }
}

@available(iOS 17.0, *)
struct CampusExplorerLargeWidget: Widget {
    let kind: String = "CampusExplorerLargeWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CampusExplorerProvider()) { entry in
            LargeWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Campus Dashboard")
        .description("Full dashboard with all your exploration stats.")
        .supportedFamilies([.systemLarge])
    }
}
