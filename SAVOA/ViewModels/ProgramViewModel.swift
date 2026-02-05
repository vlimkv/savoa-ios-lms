//
//  ProgramViewModel.swift
//  PelvicFloorApp
//

import SwiftUI
import Combine

@MainActor
final class ProgramViewModel: ObservableObject {
    @Published var course: Course?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lockedMessage: String? = nil

    private let courseService: CourseServiceProtocol
    private let progressService: ProgressService

    // Swift 6 fix: НЕ используем `.shared` в default args
    init(
        courseService: CourseServiceProtocol? = nil,
        progressService: ProgressService? = nil
    ) {
        self.courseService = courseService ?? CourseService.shared
        self.progressService = progressService ?? ProgressService.shared
    }

    func loadCourse() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            course = try await courseService.fetchCourse()
            objectWillChange.send()
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to load course: \(error)")
        }

        isLoading = false
    }

    func getLessonState(_ lessonId: String) -> LessonState {
        progressService.getLessonProgress(lessonId)?.state ?? .notStarted
    }

    func markLessonCompleted(_ lessonId: String) {
        progressService.markLessonCompleted(lessonId)
        objectWillChange.send()
    }

    func refreshProgressUI() {
        objectWillChange.send()
    }

    func showLocked(_ lesson: Lesson) {
        if let s = lesson.unlockDate, let d = ISO8601DateFormatter().date(from: s) {
            let f = DateFormatter()
            f.locale = Locale(identifier: "ru_RU")
            f.dateStyle = .long
            lockedMessage = "Урок откроется \(f.string(from: d))"
        } else {
            lockedMessage = "Этот урок пока закрыт"
        }
    }

    // MARK: - Computed

    var totalLessons: Int {
        course?.modules.flatMap { $0.days.flatMap { $0.lessons } }.count ?? 0
    }

    var completedLessons: Int {
        course?.modules
            .flatMap { $0.days.flatMap { $0.lessons } }
            .filter { getLessonState($0.id) == .completed }
            .count ?? 0
    }
}
