//
//  GratitudeJournalView.swift
//  PelvicFloorApp
//
//  Premium Gratitude Journal — Minimalist & Beautiful
//

import SwiftUI
import Combine

// MARK: - Models

struct GratitudeEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    var items: [String]
    var mood: GratitudeMood?
    
    init(id: UUID = UUID(), date: Date = Date(), items: [String] = [], mood: GratitudeMood? = nil) {
        self.id = id
        self.date = date
        self.items = items
        self.mood = mood
    }
}

enum GratitudeMood: String, Codable, CaseIterable {
    case grateful = "grateful"
    case peaceful = "peaceful"
    case happy = "happy"
    case hopeful = "hopeful"
    case loved = "loved"
    
    var icon: String {
        switch self {
        case .grateful: return "hands.sparkles.fill"
        case .peaceful: return "leaf.fill"
        case .happy: return "sun.max.fill"
        case .hopeful: return "star.fill"
        case .loved: return "heart.fill"
        }
    }
    
    var title: String {
        switch self {
        case .grateful: return "Благодарна"
        case .peaceful: return "Спокойна"
        case .happy: return "Счастлива"
        case .hopeful: return "С надеждой"
        case .loved: return "Любима"
        }
    }
    
    var color: Color {
        switch self {
        case .grateful: return Color(red: 1.0, green: 0.7, blue: 0.3)
        case .peaceful: return Color(red: 0.4, green: 0.8, blue: 0.6)
        case .happy: return Color(red: 1.0, green: 0.85, blue: 0.3)
        case .hopeful: return Color(red: 0.6, green: 0.5, blue: 1.0)
        case .loved: return Color(red: 1.0, green: 0.45, blue: 0.55)
        }
    }
}

// MARK: - View Model

@MainActor
class GratitudeJournalViewModel: ObservableObject {
    @Published var entries: [GratitudeEntry] = []
    @Published var todayEntry: GratitudeEntry?
    
    private let storageKey = "gratitude_entries"
    
    init() {
        loadEntries()
        setupTodayEntry()
    }
    
    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([GratitudeEntry].self, from: data) {
            entries = decoded.sorted { $0.date > $1.date }
        }
    }
    
    private func setupTodayEntry() {
        let today = Calendar.current.startOfDay(for: Date())
        if let existing = entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            todayEntry = existing
        } else {
            todayEntry = GratitudeEntry(date: today, items: ["", "", ""])
        }
    }
    
    func saveEntry() {
        guard var entry = todayEntry else { return }
        
        // Filter empty items
        entry.items = entry.items.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        if entry.items.isEmpty { return }
        
        // Update or add
        if let idx = entries.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: entry.date) }) {
            entries[idx] = entry
        } else {
            entries.insert(entry, at: 0)
        }
        
        // Sort by date (newest first)
        entries.sort { $0.date > $1.date }
        
        // Persist
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
        
        // Refresh today entry reference
        todayEntry = entry
        
        // Trigger UI update
        objectWillChange.send()
    }
    
    func updateItem(at index: Int, text: String) {
        guard todayEntry != nil else { return }
        while todayEntry!.items.count <= index {
            todayEntry!.items.append("")
        }
        todayEntry!.items[index] = text
    }
    
    func setMood(_ mood: GratitudeMood) {
        todayEntry?.mood = mood
    }
    
    var totalEntries: Int {
        entries.filter { !$0.items.isEmpty }.count
    }
}

// MARK: - Main View

struct GratitudeJournalView: View {
    @StateObject private var viewModel = GratitudeJournalViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Int?
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    header
                    statsRow
                    todaySection
                    moodSelector
                    saveButton
                    historySection
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onDisappear {
            viewModel.saveEntry()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.pink.opacity(0.3), Color.orange.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.pink)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Дневник благодарности")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(formattedDate)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Text("За что ты благодарна сегодня?")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM, EEEE"
        return formatter.string(from: Date()).capitalized
    }
    
    // MARK: - Stats
    
    private var statsRow: some View {
        HStack(spacing: 12) {
            MiniStatCard(
                icon: "heart.fill",
                value: "\(viewModel.totalEntries)",
                label: "записей",
                color: .pink
            )
        }
    }
    
    // MARK: - Today Section
    
    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("3 вещи, за которые благодарна")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
            
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    GratitudeInputField(
                        index: index,
                        text: Binding(
                            get: { viewModel.todayEntry?.items[safe: index] ?? "" },
                            set: { viewModel.updateItem(at: index, text: $0) }
                        ),
                        isFocused: focusedField == index
                    )
                    .focused($focusedField, equals: index)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Mood Selector
    
    private var moodSelector: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Как ты себя чувствуешь?")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(GratitudeMood.allCases, id: \.self) { mood in
                        MoodChip(
                            mood: mood,
                            isSelected: viewModel.todayEntry?.mood == mood
                        ) {
                            haptic(.light)
                            viewModel.setMood(mood)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button {
            haptic(.medium)
            viewModel.saveEntry()
            focusedField = nil
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Сохранить")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.pink, Color.orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - History
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 16) {

            if let today = viewModel.entries.first(where: { Calendar.current.isDateInToday($0.date) }),
               !today.items.isEmpty {

                Text("Сегодня")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                HistoryCard(entry: today)
            }

            let pastEntries = viewModel.entries.filter { entry in
                !Calendar.current.isDateInToday(entry.date) && !entry.items.isEmpty
            }

            if !pastEntries.isEmpty {
                HStack {
                    Text("История")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Text("\(pastEntries.count) записей")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                }

                VStack(spacing: 12) {
                    ForEach(pastEntries.prefix(10)) { entry in
                        HistoryCard(entry: entry)
                    }

                    if pastEntries.count > 10 {
                        Text("И ещё \(pastEntries.count - 10) записей...")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                    }
                }
            }
        }
    }

    
    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Supporting Views

private struct MiniStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }
}

private struct GratitudeInputField: View {
    let index: Int
    @Binding var text: String
    let isFocused: Bool
    
    private let placeholders = [
        "Например: здоровье...",
        "Например: близкие...",
        "Например: новый день..."
    ]
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.pink.opacity(isFocused ? 0.3 : 0.15))
                    .frame(width: 28, height: 28)
                
                Text("\(index + 1)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.pink)
            }
            
            TextField(placeholders[safe: index] ?? "", text: $text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .accentColor(.pink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(isFocused ? 0.08 : 0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isFocused ? Color.pink.opacity(0.4) : Color.clear, lineWidth: 1)
                )
        )
        .animation(.easeOut(duration: 0.2), value: isFocused)
    }
}

private struct MoodChip: View {
    let mood: GratitudeMood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: mood.icon)
                    .font(.system(size: 12, weight: .semibold))
                
                Text(mood.title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(isSelected ? .black : mood.color)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? mood.color : mood.color.opacity(0.15))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

private struct HistoryCard: View {
    let entry: GratitudeEntry
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        
        let calendar = Calendar.current
        if calendar.isDateInYesterday(entry.date) {
            return "Вчера"
        } else if calendar.isDate(entry.date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: entry.date).capitalized
        } else {
            formatter.dateFormat = "d MMMM"
            return formatter.string(from: entry.date)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(formattedDate)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                if let mood = entry.mood {
                    HStack(spacing: 4) {
                        Image(systemName: mood.icon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(mood.title)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(mood.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(mood.color.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(entry.items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.pink.opacity(0.6))
                            .frame(width: 16)
                        
                        Text(item)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                )
        )
    }
}

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Array Extension

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    NavigationStack {
        GratitudeJournalView()
    }
}
