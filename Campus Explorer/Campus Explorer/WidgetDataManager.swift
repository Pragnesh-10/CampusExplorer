//
//  WidgetDataManager.swift
//  Campus Explorer
//
//  Manages data sharing between the main app and widgets
//

import Foundation
import WidgetKit

@MainActor
class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private let defaults = UserDefaults(suiteName: "group.campus.explorer") ?? UserDefaults.standard
    
    private init() {}
    
    func updateWidgetData(
        steps: Int,
        distance: Double,
        calories: Double,
        streak: Int,
        points: Int,
        explorationPercentage: Double
    ) {
        defaults.set(steps, forKey: "widget_steps")
        defaults.set(distance, forKey: "widget_distance")
        defaults.set(calories, forKey: "widget_calories")
        defaults.set(streak, forKey: "widget_streak")
        defaults.set(points, forKey: "widget_points")
        defaults.set(explorationPercentage, forKey: "widget_exploration")
        defaults.set(Date(), forKey: "widget_lastUpdated")
        
        // Request widget refresh
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func getWidgetData() -> (steps: Int, distance: Double, calories: Double, streak: Int, points: Int, exploration: Double) {
        return (
            steps: defaults.integer(forKey: "widget_steps"),
            distance: defaults.double(forKey: "widget_distance"),
            calories: defaults.double(forKey: "widget_calories"),
            streak: defaults.integer(forKey: "widget_streak"),
            points: defaults.integer(forKey: "widget_points"),
            exploration: defaults.double(forKey: "widget_exploration")
        )
    }
}

// Extension to easily update widget from LocationManager changes
extension LocationManager {
    func updateWidget(streak: Int = 0, points: Int = 0, exploration: Double = 0) {
        Task { @MainActor in
            WidgetDataManager.shared.updateWidgetData(
                steps: stepCount,
                distance: totalDistance,
                calories: caloriesBurned,
                streak: streak,
                points: points,
                explorationPercentage: exploration
            )
        }
    }
}
