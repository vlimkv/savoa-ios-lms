//
//  HomeViewModel.swift
//  PelvicFloorApp
//
//  Created by 7Я on 04.12.2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var course: Course?
    @Published var nextLesson: Lesson?
    @Published var todayLesson: Lesson?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var theoryLessons: [TheoryLesson] = []

    @Published var completedLessons = 0
    @Published var totalLessons = 0
    @Published var didInitialLoad = false

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

    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            let course = try await courseService.fetchCourse()
            self.course = course

            updateStats()
            findNextLesson()

            await loadTheory()
        } catch {
            errorMessage = "Не удалось загрузить данные"
        }

        isLoading = false
    }

    private func updateStats() {
        guard let course = course else { return }
        completedLessons = progressService.getTotalCompletedLessons()
        totalLessons = countTotalLessons(in: course)
    }

    private func loadTheory() async {
        do {
            guard let token = AuthService.shared.getToken(), !token.isEmpty else {
                print("⚠️ No token for theory request")
                return
            }

            let dto = try await TheoryService.shared.fetchTheoryLessons(token: token)

            self.theoryLessons = dto.map { d in
                TheoryLesson(
                    id: d.id,
                    title: d.title,
                    subtitle: d.subtitle ?? "",
                    duration: d.durationLabel ?? "",
                    youtubeURL: d.youtubeURL,
                    thumbnailGradient: (d.thumbnailGradient ?? ["#F2667C", "#B33A9A"]).map { Color(hex: $0) },
                    category: d.category ?? "",
                    thumbnailGif: "giphy"
                )
            }
        } catch {
            print("❌ loadTheory error:", error)
        }
    }

    private func findNextLesson() {
        guard let course = course else { return }

        for module in course.modules.sorted(by: { $0.order < $1.order }) {
            for day in module.days.sorted(by: { $0.order < $1.order }) {
                for lesson in day.lessons.sorted(by: { $0.order < $1.order }) {
                    if !progressService.isLessonCompleted(lesson.id) {
                        nextLesson = lesson
                        todayLesson = lesson
                        return
                    }
                }
            }
        }

        if let lastModule = course.modules.sorted(by: { $0.order > $1.order }).first,
           let lastDay = lastModule.days.sorted(by: { $0.order > $1.order }).first,
           let lastLesson = lastDay.lessons.sorted(by: { $0.order > $1.order }).first {
            nextLesson = lastLesson
            todayLesson = lastLesson
        }
    }

    private func countTotalLessons(in course: Course) -> Int {
        var count = 0
        for module in course.modules {
            for day in module.days {
                count += day.lessons.count
            }
        }
        return count
    }

    func getProgressPercentage() -> Double {
        guard totalLessons > 0 else { return 0 }
        return Double(completedLessons) / Double(totalLessons)
    }

    func initialLoad() async {
        guard !didInitialLoad else { return }
        didInitialLoad = true
        await loadData()
    }
}
