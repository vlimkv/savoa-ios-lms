//
//  NotificationService.swift
//  SAVOA
//
//  Created by 7Я on 10.01.2026.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    private let morningId = "workout_morning"

    func requestPermissionIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                print("❌ requestAuthorization error:", error)
                return false
            }
        @unknown default:
            return false
        }
    }

    func enableDailyWorkoutReminders() async {
        let allowed = await requestPermissionIfNeeded()
        guard allowed else {
            await disableDailyWorkoutReminders()
            return
        }
        await scheduleMorning()
    }

    func disableDailyWorkoutReminders() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [morningId])
        center.removeDeliveredNotifications(withIdentifiers: [morningId])
    }

    // MARK: - Private

    private func scheduleMorning() async {
        let center = UNUserNotificationCenter.current()

        // убрать старое
        center.removePendingNotificationRequests(withIdentifiers: [morningId])

        schedule(
            id: morningId,
            hour: 7, minute: 0,
            title: "Доброе утро",
            body: "Тренировка доступна. 10–20 минут для тела — и день пойдёт мягче."
        )
    }

    private func schedule(id: String, hour: Int, minute: Int, title: String, body: String) {
        var dc = DateComponents()
        dc.hour = hour
        dc.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req) { error in
            if let error {
                print("❌ schedule \(id) error:", error)
            } else {
                print("✅ scheduled:", id)
            }
        }
    }
}
