//
//  Progress.swift
//  PelvicFloorApp
//
//  Created by 7Я on 04.12.2025.
//

import Foundation

public struct LessonProgress: Codable {
    public var lessonID: String
    public var state: LessonState
    public var lastPosition: Double
    public var completedAt: Date?
    public var startedAt: Date?

    public init(
        lessonID: String,
        state: LessonState,
        lastPosition: Double,
        completedAt: Date? = nil,
        startedAt: Date? = nil
    ) {
        self.lessonID = lessonID
        self.state = state
        self.lastPosition = lastPosition
        self.completedAt = completedAt
        self.startedAt = startedAt
    }
}

public struct Progress: Codable {
    public var completedLessonIDs: Set<String>
    public var lessonProgress: [String: LessonProgress]

    public init() {
        self.completedLessonIDs = []
        self.lessonProgress = [:]
    }
}
