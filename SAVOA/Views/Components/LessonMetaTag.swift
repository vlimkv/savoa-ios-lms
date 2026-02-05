//
//  LessonMetaTag.swift
//  PelvicFloorApp
//
//  Created by 7Я on 12.12.2025.
//

import SwiftUI

struct LessonMetaTag: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(.white.opacity(0.95))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.12))
        )
    }
}
