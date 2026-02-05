//
//  LessonProgressReporter.swift
//  SAVOA
//
//  Created by 7Я on 08.01.2026.
//

import Foundation

final class LessonProgressReporter {
    private let lessonId: String
    private let sync = ProgressSyncService.shared

    private var timer: Timer?
    private var lastSentSeconds: Int = 0

    init(lessonId: String) {
        self.lessonId = lessonId
    }

    func start(getCurrentSeconds: @escaping () -> Int) {
        stop()

        let s0 = max(0, getCurrentSeconds())
        lastSentSeconds = s0
        Task { await sync.pushHeartbeat(lessonId: lessonId, seconds: s0) }

        timer = Timer.scheduledTimer(withTimeInterval: 12, repeats: true) { [weak self] _ in
            guard let self else { return }
            let current = max(0, getCurrentSeconds())
            if current <= self.lastSentSeconds { return }
            self.lastSentSeconds = current
            Task { await self.sync.pushHeartbeat(lessonId: self.lessonId, seconds: current) }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func complete(finalSeconds: Int) {
        stop()
        Task { await sync.pushCompletion(lessonId: lessonId, seconds: max(0, finalSeconds)) }
    }
}
