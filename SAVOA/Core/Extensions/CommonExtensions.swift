//
//  CommonExtensions.swift
//  PelvicFloorApp
//
//  Created by 7Я on 04.12.2025.
//

import Foundation
import SwiftUI

// MARK: - Date Extensions

extension Date {
    func isToday() -> Bool {
        Calendar.current.isDateInToday(self)
    }
    
    func isYesterday() -> Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    func startOfDay() -> Date {
        Calendar.current.startOfDay(for: self)
    }
    
    func formatted(style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}

// MARK: - Color Extensions (Pure Black & White)

extension Color {
    // Background
    static let backgroundPrimary = Color.black
    static let backgroundSecondary = Color(white: 0.05)
    
    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.6)
    static let textTertiary = Color(white: 0.4)
    
    // Accent (minimal gray)
    static let accentGray = Color(white: 0.8)
    
    // Card backgrounds
    static let cardBackground = Color(white: 0.1)
    static let cardBackgroundElevated = Color(white: 0.15)
}

// MARK: - Int Extensions

extension Int {
    func formatDuration() -> String {
        let minutes = self / 60
        let seconds = self % 60
        if minutes > 0 {
            return "\(minutes) мин"
        } else {
            return "\(seconds) сек"
        }
    }
}

// MARK: - String Extensions

extension String {
    func isValidEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
}
