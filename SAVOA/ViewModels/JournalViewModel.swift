//
//  JournalViewModel.swift
//  PelvicFloorApp
//
//  Created by 7Я on 08.12.2025.
//

import Foundation
import Combine

final class JournalViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = JournalEntry.sample
    
    func addEntry(bodyFeeling: Int, energy: Int, mood: Int, note: String) {
        let cleanedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let newEntry = JournalEntry(
            bodyFeeling: bodyFeeling,
            energy: energy,
            mood: mood,
            note: cleanedNote
        )
        
        entries.insert(newEntry, at: 0)
    }
}
