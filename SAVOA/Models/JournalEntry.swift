//
//  JournalEntry.swift
//  PelvicFloorApp
//
//  Created by 7Я on 04.12.2025.
//

import Foundation

struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let bodyFeeling: Int   // 1–5
    let energy: Int        // 1–5
    let mood: Int          // 1–5
    let note: String
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        bodyFeeling: Int,
        energy: Int,
        mood: Int,
        note: String
    ) {
        self.id = id
        self.date = date
        self.bodyFeeling = bodyFeeling
        self.energy = energy
        self.mood = mood
        self.note = note
    }
}

// Примеры для предпросмотра и заглушки
extension JournalEntry {
    static let sample: [JournalEntry] = [
        .init(
            date: Date(),
            bodyFeeling: 4,
            energy: 3,
            mood: 4,
            note: "После практики тело чувствует себя легче, дыхание ровнее."
        ),
        .init(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            bodyFeeling: 3,
            energy: 2,
            mood: 3,
            note: "Сегодня взяла только мягкую часть урока, больше отдыхала."
        )
    ]
}
