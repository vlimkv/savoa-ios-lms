//
//  ProgressService.swift
//  PelvicFloorApp
//
//  Created by 7Я on 04.12.2025.
//

import Foundation

class ProgressService {
    static let shared = ProgressService()
    
    private let storage: StorageServiceProtocol
    fileprivate var progress: Progress
    
    private init(storage: StorageServiceProtocol = StorageService.shared) {
        self.storage = storage
        self.progress = storage.load(Progress.self, forKey: StorageService.Keys.progress) ?? Progress()
    }
    
    // MARK: - Lesson Progress
    
    func markLessonStarted(_ lessonId: String) {
        if progress.lessonProgress[lessonId] == nil {
            progress.lessonProgress[lessonId] = LessonProgress(
                lessonID: lessonId,
                state: .inProgress,
                lastPosition: 0,
                completedAt: nil,
                startedAt: Date()
            )
            save()
        }
    }
    
    func markLessonCompleted(_ lessonId: String) {
        var lessonProgress = progress.lessonProgress[lessonId] ?? LessonProgress(
            lessonID: lessonId,
            state: .notStarted,
            lastPosition: 0,
            completedAt: nil,
            startedAt: nil
        )

        lessonProgress.state = .completed
        lessonProgress.completedAt = Date()
        progress.lessonProgress[lessonId] = lessonProgress
        progress.completedLessonIDs.insert(lessonId)

        save()
    }
    
    func updateLessonPosition(_ lessonId: String, position: Double) {
        var lessonProgress = progress.lessonProgress[lessonId] ?? LessonProgress(
            lessonID: lessonId,
            state: .inProgress,
            lastPosition: 0,
            completedAt: nil,
            startedAt: Date()
        )
        
        lessonProgress.lastPosition = position
        lessonProgress.state = .inProgress
        progress.lessonProgress[lessonId] = lessonProgress
        
        save()
    }
    
    func getLessonProgress(_ lessonId: String) -> LessonProgress? {
        return progress.lessonProgress[lessonId]
    }
    
    func isLessonCompleted(_ lessonId: String) -> Bool {
        return progress.completedLessonIDs.contains(lessonId)
    }
    
    // MARK: - Stats
    
    func getProgress() -> Progress {
        return progress
    }
    
    func getTotalCompletedLessons() -> Int {
        return progress.completedLessonIDs.count
    }
    
    private func save() {
        storage.save(progress, forKey: StorageService.Keys.progress)
    }
    
    func resetProgress() {
        progress = Progress()
        save()
    }
}

extension ProgressService {
    func overwriteProgress(_ newValue: Progress) {
        self.progress = newValue
        storage.save(progress, forKey: StorageService.Keys.progress)
    }
}
