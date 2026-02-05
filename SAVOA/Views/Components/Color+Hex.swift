//
//  Color+Hex.swift
//  SAVOA
//
//  Created by 7Я on 10.01.2026.
//

import SwiftUI

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }

        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        self = Color(red: r, green: g, blue: b)
    }
}
