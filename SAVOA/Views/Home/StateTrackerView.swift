//
//  StateTrackerView.swift
//  PelvicFloorApp
//
//  Premium State Tracker — Track Your Feelings & Symptoms
//

import SwiftUI
import Combine

// MARK: - Models

struct StateEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    var overallMood: OverallMood
    var energy: Int // 1-5
    var symptoms: Set<Symptom>
    var notes: String
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        overallMood: OverallMood = .neutral,
        energy: Int = 3,
        symptoms: Set<Symptom> = [],
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.overallMood = overallMood
        self.energy = energy
        self.symptoms = symptoms
        self.notes = notes
    }
}

enum OverallMood: String, Codable, CaseIterable {
    case great = "great"
    case good = "good"
    case neutral = "neutral"
    case low = "low"
    case difficult = "difficult"
    
    var emoji: String {
        switch self {
        case .great: return "😊"
        case .good: return "🙂"
        case .neutral: return "😐"
        case .low: return "😔"
        case .difficult: return "😢"
        }
    }
    
    var title: String {
        switch self {
        case .great: return "Отлично"
        case .good: return "Хорошо"
        case .neutral: return "Норм"
        case .low: return "Так себе"
        case .difficult: return "Тяжело"
        }
    }
    
    var color: Color {
        switch self {
        case .great: return Color(red: 0.3, green: 0.85, blue: 0.5)
        case .good: return Color(red: 0.5, green: 0.8, blue: 0.9)
        case .neutral: return Color(red: 0.7, green: 0.7, blue: 0.7)
        case .low: return Color(red: 0.9, green: 0.7, blue: 0.4)
        case .difficult: return Color(red: 0.9, green: 0.45, blue: 0.45)
        }
    }
}

enum Symptom: String, Codable, CaseIterable, Hashable {
    case discomfort = "discomfort"
    case tension = "tension"
    case heaviness = "heaviness"
    case weakness = "weakness"
    case pain = "pain"
    case leakage = "leakage"
    case bloating = "bloating"
    case fatigue = "fatigue"
    
    var title: String {
        switch self {
        case .discomfort: return "Дискомфорт"
        case .tension: return "Напряжение"
        case .heaviness: return "Тяжесть"
        case .weakness: return "Слабость"
        case .pain: return "Боль"
        case .leakage: return "Подтекание"
        case .bloating: return "Вздутие"
        case .fatigue: return "Усталость"
        }
    }
    
    var icon: String {
        switch self {
        case .discomfort: return "exclamationmark.circle"
        case .tension: return "bolt.fill"
        case .heaviness: return "arrow.down.circle"
        case .weakness: return "battery.25"
        case .pain: return "staroflife.fill"
        case .leakage: return "drop.fill"
        case .bloating: return "circle.fill"
        case .fatigue: return "moon.zzz.fill"
        }
    }
}

// MARK: - View Model

@MainActor
class StateTrackerViewModel: ObservableObject {
    @Published var entries: [StateEntry] = []
    @Published var todayEntry: StateEntry
    
    private let storageKey = "state_entries"
    
    init() {
        self.todayEntry = StateEntry()
        loadEntries()
        setupTodayEntry()
    }
    
    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([StateEntry].self, from: data) {
            entries = decoded.sorted { $0.date > $1.date }
        }
    }
    
    private func setupTodayEntry() {
        let today = Calendar.current.startOfDay(for: Date())
        if let existing = entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            todayEntry = existing
        }
    }
    
    func saveEntry() {
        // Update or add
        if let idx = entries.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: todayEntry.date) }) {
            entries[idx] = todayEntry
        } else {
            entries.insert(todayEntry, at: 0)
        }
        
        // Sort by date (newest first)
        entries.sort { $0.date > $1.date }
        
        // Persist
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
        
        // Trigger UI update
        objectWillChange.send()
    }
    
    func setMood(_ mood: OverallMood) {
        todayEntry.overallMood = mood
    }
    
    func setEnergy(_ level: Int) {
        todayEntry.energy = max(1, min(5, level))
    }
    
    func toggleSymptom(_ symptom: Symptom) {
        if todayEntry.symptoms.contains(symptom) {
            todayEntry.symptoms.remove(symptom)
        } else {
            todayEntry.symptoms.insert(symptom)
        }
    }
    
    var averageMoodThisWeek: String {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weekEntries = entries.filter { $0.date >= weekAgo }
        
        guard !weekEntries.isEmpty else { return "—" }
        
        let moodValues = weekEntries.map { entry in
            switch entry.overallMood {
            case .great: return 5
            case .good: return 4
            case .neutral: return 3
            case .low: return 2
            case .difficult: return 1
            }
        }
        
        let average = Double(moodValues.reduce(0, +)) / Double(moodValues.count)
        
        if average >= 4.5 { return "😊" }
        else if average >= 3.5 { return "🙂" }
        else if average >= 2.5 { return "😐" }
        else if average >= 1.5 { return "😔" }
        else { return "😢" }
    }
    
    var totalEntries: Int {
        entries.count
    }
}

// MARK: - Main View

struct StateTrackerView: View {
    @StateObject private var viewModel = StateTrackerViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNoteFocused: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    header
                    moodSection
                    energySection
                    symptomsSection
                    notesSection
                    saveButton
                    historySection
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .navigationBarBackButtonHidden(true)
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
                                colors: [Color.green.opacity(0.3), Color.cyan.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Как ты себя чувствуешь?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(formattedDate)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // Mini stats
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Text("За неделю:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    Text(viewModel.averageMoodThisWeek)
                        .font(.system(size: 16))
                }
                
                HStack(spacing: 6) {
                    Text("Записей:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    Text("\(viewModel.totalEntries)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM, EEEE"
        return formatter.string(from: Date()).capitalized
    }
    
    // MARK: - Mood Section
    
    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Общее настроение")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
            
            HStack(spacing: 8) {
                ForEach(OverallMood.allCases, id: \.self) { mood in
                    MoodButton(
                        mood: mood,
                        isSelected: viewModel.todayEntry.overallMood == mood
                    ) {
                        haptic(.light)
                        viewModel.setMood(mood)
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Energy Section
    
    private var energySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Уровень энергии")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text("\(viewModel.todayEntry.energy)/5")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.cyan)
            }
            
            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { level in
                    EnergyLevel(
                        level: level,
                        isActive: level <= viewModel.todayEntry.energy
                    ) {
                        haptic(.light)
                        viewModel.setEnergy(level)
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Symptoms Section
    
    private var symptomsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Симптомы (если есть)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(Symptom.allCases, id: \.self) { symptom in
                    SymptomChip(
                        symptom: symptom,
                        isSelected: viewModel.todayEntry.symptoms.contains(symptom)
                    ) {
                        haptic(.light)
                        viewModel.toggleSymptom(symptom)
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Заметки")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
            
            TextField("Что ещё хочешь отметить?", text: $viewModel.todayEntry.notes, axis: .vertical)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .accentColor(.green)
                .lineLimit(3...5)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(isNoteFocused ? Color.green.opacity(0.4) : Color.clear, lineWidth: 1)
                        )
                )
                .focused($isNoteFocused)
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button {
            haptic(.medium)
            viewModel.saveEntry()
            isNoteFocused = false
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
                    colors: [Color.green, Color.cyan],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - History Section
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            let pastEntries = viewModel.entries.filter { entry in
                !Calendar.current.isDate(entry.date, inSameDayAs: Date())
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
                
                VStack(spacing: 10) {
                    ForEach(pastEntries.prefix(14)) { entry in
                        StateHistoryCard(entry: entry)
                    }
                    
                    if pastEntries.count > 14 {
                        Text("И ещё \(pastEntries.count - 14) записей...")
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

private struct MoodButton: View {
    let mood: OverallMood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(mood.emoji)
                    .font(.system(size: 28))
                
                Text(mood.title)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(isSelected ? mood.color : .white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? mood.color.opacity(0.2) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isSelected ? mood.color.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

private struct EnergyLevel: View {
    let level: Int
    let isActive: Bool
    let action: () -> Void
    
    private var color: Color {
        switch level {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        case 5: return .cyan
        default: return .gray
        }
    }
    
    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isActive ? color : Color.white.opacity(0.08))
                .frame(height: 36)
                .overlay(
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isActive ? .black.opacity(0.7) : .white.opacity(0.2))
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

private struct SymptomChip: View {
    let symptom: Symptom
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symptom.icon)
                    .font(.system(size: 12, weight: .semibold))
                
                Text(symptom.title)
                    .font(.system(size: 12, weight: .semibold))
                
                Spacer()
            }
            .foregroundColor(isSelected ? .orange : .white.opacity(0.6))
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.orange.opacity(0.15) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isSelected ? Color.orange.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

private struct StateHistoryCard: View {
    let entry: StateEntry
    
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
            HStack(spacing: 14) {
                // Emoji
                Text(entry.overallMood.emoji)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 6) {
                    // Date and mood title
                    HStack {
                        Text(formattedDate)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Text(entry.overallMood.title)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(entry.overallMood.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(entry.overallMood.color.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    
                    // Stats row
                    HStack(spacing: 16) {
                        // Energy
                        HStack(spacing: 5) {
                            ForEach(1...5, id: \.self) { level in
                                Circle()
                                    .fill(level <= entry.energy ? energyColor(level) : Color.white.opacity(0.1))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        
                        // Symptoms
                        if !entry.symptoms.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.orange.opacity(0.8))
                                Text("\(entry.symptoms.count) симптомов")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                }
            }
            
            // Notes if present
            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
                    .padding(.top, 4)
            }
            
            // Symptoms tags if present
            if !entry.symptoms.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(entry.symptoms), id: \.self) { symptom in
                            HStack(spacing: 4) {
                                Image(systemName: symptom.icon)
                                    .font(.system(size: 9, weight: .semibold))
                                Text(symptom.title)
                                    .font(.system(size: 9, weight: .semibold))
                            }
                            .foregroundColor(.orange.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(Capsule())
                        }
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
    
    private func energyColor(_ level: Int) -> Color {
        switch level {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        case 5: return .cyan
        default: return .gray
        }
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

#Preview {
    NavigationStack {
        StateTrackerView()
    }
}
