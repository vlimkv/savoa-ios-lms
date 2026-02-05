//
//  ProgressSyncService.swift
//  SAVOA
//
//  Created by 7Я on 08.01.2026.
//

import Foundation

final class ProgressSyncService {
    static let shared = ProgressSyncService()

    private let api: RemoteProgressAPI
    private let local: ProgressService

    private init() {
        self.local = .shared
        self.api = try! RemoteProgressAPI()
    }

    // GET /progress -> merge -> save local
    func pullAndMerge() async {
        do {
            let rows = try await api.fetchProgress()
            merge(serverRows: rows)
        } catch {
            // silent fail
        }
    }

    // POST heartbeat
    func pushHeartbeat(lessonId: String, seconds: Int) async {
        let s = max(0, seconds)
        do { try await api.pushProgress(lessonId: lessonId, secondsWatched: s, completed: nil) } catch {}
    }

    // POST complete
    func pushCompletion(lessonId: String, seconds: Int) async {
        let s = max(0, seconds)
        do { try await api.pushProgress(lessonId: lessonId, secondsWatched: s, completed: true) } catch {}
    }

    // MARK: - Merge

    private func merge(serverRows: [BackendLessonProgress]) {
        var p = local.getProgress()

        for row in serverRows {
            let lessonId = row.lesson_id
            let serverSeconds = Double(max(0, row.seconds_watched))
            let serverCompleted = row.completed

            let localEntry = p.lessonProgress[lessonId]
            let mergedSeconds = max(localEntry?.lastPosition ?? 0, serverSeconds)

            var merged = localEntry ?? LessonProgress(
                lessonID: lessonId,
                state: .notStarted,
                lastPosition: 0,
                completedAt: nil,
                startedAt: nil
            )

            merged.lastPosition = mergedSeconds

            if serverCompleted || merged.state == .completed {
                merged.state = .completed
                p.completedLessonIDs.insert(lessonId)
                if merged.completedAt == nil { merged.completedAt = Date() }
            } else if mergedSeconds > 0 {
                merged.state = .inProgress
            }

            if merged.startedAt == nil, mergedSeconds > 0 {
                merged.startedAt = Date()
            }

            p.lessonProgress[lessonId] = merged
        }

        local.overwriteProgress(p)
    }
}
