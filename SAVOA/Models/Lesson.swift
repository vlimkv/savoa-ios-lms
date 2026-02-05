//
//  Lesson.swift
//  PelvicFloorApp
//
//  Created by 7Я on 04.12.2025.
//

import Foundation

enum LessonType: String, Codable {
    case video
    case article
    case audio
}

public enum LessonState: String, Codable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed
}

struct Lesson: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let type: LessonType
    let duration: Int
    let videoURL: String?
    let thumbnailURL: String?
    let notes: String?
    let order: Int

    // ✅ from API
    let isLocked: Bool?
    let unlockDate: String?

    var state: LessonState = .notStarted
    var lastWatchedPosition: Double = 0.0

    enum CodingKeys: String, CodingKey {
        case id, title, description, type, duration, order, notes
        case videoURL = "video_url"
        case thumbnailURL = "thumbnail_url"
        case isLocked = "is_locked"
        case unlockDate = "unlock_date"
    }
}

extension Lesson {
    var locked: Bool { (isLocked ?? false) }
}
