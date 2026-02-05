//
//  StatisticsView.swift
//  Campus Explorer
//
//  Detailed statistics and activity reports
//

import SwiftUI
import Charts

struct StatisticsView: View {
    @ObservedObject var locationManager: LocationManager
    @Bindable var achievementsManager: AchievementsManager
    @State private var selectedPeriod = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Period Selector
                    Picker("Period", selection: $selectedPeriod) {
                        Text("Today").tag(0)
                        Text("Week").tag(1)
                        Text("Month").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Summary Cards
                    summaryCardsView
                    
                    // Steps Chart
                    stepsChartView
                    
                    // Distance Chart
                    distanceChartView
                    
                    // Calories Card
                    caloriesCardView
                    
                    // Activity Breakdown
                    activityBreakdownView
                    
                    // Records
                    recordsView
                }
                .padding(.vertical)
            }
            .navigationTitle("Statistics")
        }
    }
    
    // MARK: - Summary Cards
    private var summaryCardsView: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(
                title: "Steps",
                value: formattedNumber(currentSteps),
                icon: "figure.walk",
                color: .blue,
                trend: "+12%"
            )
            
            StatCard(
                title: "Distance",
                value: formattedDistance(currentDistance),
                icon: "map",
                color: .green,
                trend: "+8%"
            )
            
            StatCard(
                title: "Calories",
                value: "\(currentCalories)",
                icon: "flame.fill",
                color: .orange,
                trend: "+15%"
            )
            
            StatCard(
                title: "Active Time",
                value: formattedDuration(currentActiveMinutes),
                icon: "clock.fill",
                color: .purple,
                trend: "+5%"
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Steps Chart
    private var stepsChartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Steps Over Time")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(stepsData, id: \.date) { item in
                    BarMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Steps", item.value)
                    )
                    .foregroundStyle(.blue.gradient)
                    .cornerRadius(4)
                }
                
                RuleMark(y: .value("Goal", achievementsManager.goals.dailySteps))
                    .foregroundStyle(.red.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Goal")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
            }
            .frame(height: 200)
            .padding(.horizontal)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    // MARK: - Distance Chart
    private var distanceChartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Distance Traveled")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(distanceData, id: \.date) { item in
                    AreaMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Distance", item.value)
                    )
                    .foregroundStyle(.green.opacity(0.3))
                    
                    LineMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Distance", item.value)
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            .frame(height: 200)
            .padding(.horizontal)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    // MARK: - Calories Card
    private var caloriesCardView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("Calories Burned")
                    .font(.headline)
            }
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(currentCalories)")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(.orange)
                    Text("kcal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                    .frame(height: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    CalorieBreakdownRow(
                        label: "Walking",
                        value: Int(Double(currentCalories) * 0.7),
                        color: .blue
                    )
                    CalorieBreakdownRow(
                        label: "Running",
                        value: Int(Double(currentCalories) * 0.2),
                        color: .green
                    )
                    CalorieBreakdownRow(
                        label: "Other",
                        value: Int(Double(currentCalories) * 0.1),
                        color: .purple
                    )
                }
                
                Spacer()
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    // MARK: - Activity Breakdown
    private var activityBreakdownView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Breakdown")
                .font(.headline)
            
            HStack {
                Spacer()
                
                Chart {
                    ForEach(activityBreakdown, id: \.name) { activity in
                        SectorMark(
                            angle: .value("Value", activity.value),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(activity.color)
                        .cornerRadius(4)
                    }
                }
                .frame(width: 150, height: 150)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(activityBreakdown, id: \.name) { activity in
                        HStack {
                            Circle()
                                .fill(activity.color)
                                .frame(width: 12, height: 12)
                            Text(activity.name)
                                .font(.caption)
                            Spacer()
                            Text("\(Int(activity.value))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(width: 120)
                
                Spacer()
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    // MARK: - Records
    private var recordsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Records")
                .font(.headline)
            
            HStack(spacing: 16) {
                RecordCard(
                    title: "Most Steps",
                    value: "15,234",
                    date: "Jan 15",
                    icon: "trophy.fill",
                    color: .yellow
                )
                
                RecordCard(
                    title: "Longest Distance",
                    value: "12.5 km",
                    date: "Feb 3",
                    icon: "medal.fill",
                    color: .orange
                )
                
                RecordCard(
                    title: "Best Streak",
                    value: "\(achievementsManager.streakData.longestStreak) days",
                    date: "Current",
                    icon: "flame.fill",
                    color: .red
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    // MARK: - Computed Properties
    private var currentSteps: Int {
        switch selectedPeriod {
        case 0: return locationManager.stepCount
        case 1: return achievementsManager.weekSteps
        case 2: return achievementsManager.weekSteps * 4
        default: return locationManager.stepCount
        }
    }
    
    private var currentDistance: Double {
        switch selectedPeriod {
        case 0: return locationManager.totalDistance
        case 1: return achievementsManager.weekDistance
        case 2: return achievementsManager.weekDistance * 4
        default: return locationManager.totalDistance
        }
    }
    
    private var currentCalories: Int {
        // Rough estimate: 0.04 calories per step
        return Int(Double(currentSteps) * 0.04)
    }
    
    private var currentActiveMinutes: Int {
        // Rough estimate: 100 steps per minute of walking
        return currentSteps / 100
    }
    
    private var stepsData: [ChartDataPoint] {
        let calendar = Calendar.current
        var data: [ChartDataPoint] = []
        let days = selectedPeriod == 0 ? 1 : (selectedPeriod == 1 ? 7 : 30)
        
        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let steps = i == 0 ? locationManager.stepCount : Int.random(in: 3000...12000)
                data.append(ChartDataPoint(date: date, value: Double(steps)))
            }
        }
        return data.reversed()
    }
    
    private var distanceData: [ChartDataPoint] {
        let calendar = Calendar.current
        var data: [ChartDataPoint] = []
        let days = selectedPeriod == 0 ? 1 : (selectedPeriod == 1 ? 7 : 30)
        
        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let distance = i == 0 ? locationManager.totalDistance : Double.random(in: 1000...8000)
                data.append(ChartDataPoint(date: date, value: distance))
            }
        }
        return data.reversed()
    }
    
    private var activityBreakdown: [ActivityData] {
        [
            ActivityData(name: "Walking", value: 65, color: .blue),
            ActivityData(name: "Running", value: 20, color: .green),
            ActivityData(name: "Cycling", value: 10, color: .orange),
            ActivityData(name: "Other", value: 5, color: .purple)
        ]
    }
    
    // MARK: - Formatters
    private func formattedNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    private func formattedDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        }
        return String(format: "%.0f m", meters)
    }
    
    private func formattedDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
                Text(trend)
                    .font(.caption)
                    .foregroundStyle(.green)
            }
            
            Text(value)
                .font(.title2)
                .bold()
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CalorieBreakdownRow: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
            Spacer()
            Text("\(value) kcal")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct RecordCard: View {
    let title: String
    let value: String
    let date: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.headline)
                .bold()
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Text(date)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Data Models
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct ActivityData {
    let name: String
    let value: Double
    let color: Color
}

#Preview {
    StatisticsView(
        locationManager: LocationManager(),
        achievementsManager: AchievementsManager()
    )
}
