//
//  AccessibilityManager.swift
//  Campus Explorer
//
//  Manages app-wide accessibility settings and overrides
//

import SwiftUI
import Observation

@Observable
class AccessibilityManager {
    var isVoiceOverRunning: Bool = UIAccessibility.isVoiceOverRunning
    var preferHighContrast: Bool = false
    var largeTextEnabled: Bool = false
    
    init() {
        // Observe VoiceOver changes
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
        }
        
        // Check system settings
        preferHighContrast = UIAccessibility.isDarkerSystemColorsEnabled
    }
    
    // MARK: - Helpers
    func color(for color: Color) -> Color {
        guard preferHighContrast else { return color }
        
        // Simple high contrast mapping
        switch color {
        case .gray: return .black
        case .blue: return .blue // Keep primary
        case .red: return .red
        default: return color
        }
    }
}
