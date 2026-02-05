//
//  TheoryLessonDTO.swift
//  SAVOA
//
//  Created by 7Я on 10.01.2026.
//

import Foundation

struct TheoryLessonDTO: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String?
    let durationLabel: String?
    let youtubeURL: String
    let thumbnailGradient: [String]?
    let category: String?
    let orderIndex: Int?
    let isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, category
        case durationLabel = "duration_label"
        case youtubeURL = "youtube_url"
        case thumbnailGradient = "thumbnail_gradient"
        case orderIndex = "order_index"
        case isActive = "is_active"
    }
}
