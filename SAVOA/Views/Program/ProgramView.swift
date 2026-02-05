//
//  ProgramView.swift
//  PelvicFloorApp
//
//  RE:STORE — Ultra Minimal Square Design
//

import SwiftUI

struct ProgramView: View {
    @StateObject private var viewModel = ProgramViewModel()
    
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize
    
    private var isIPad: Bool { hSize == .regular && vSize == .regular }
    private var hPad: CGFloat { isIPad ? 32 : 20 }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.isLoading {
                loadingView
            } else if let course = viewModel.course {
                contentView(course)
            } else {
                errorView
            }
        }
        .navigationBarHidden(true)
        .task {
            await ProgressSyncService.shared.pullAndMerge()
            await viewModel.loadCourse()
        }
        .alert("Закрыто", isPresented: Binding(
            get: { viewModel.lockedMessage != nil },
            set: { if !$0 { viewModel.lockedMessage = nil } }
        )) {
            Button("Ок", role: .cancel) { viewModel.lockedMessage = nil }
        } message: {
            Text(viewModel.lockedMessage ?? "")
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(.white.opacity(0.5))
                .scaleEffect(1.0)
            
            Text("RE:STORE")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.25))
                .tracking(4)
        }
    }

    // MARK: - Error

    private var errorView: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32, weight: .thin))
                .foregroundColor(.white.opacity(0.3))

            Text("Не удалось загрузить")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.5))

            Button {
                Task { await viewModel.loadCourse() }
            } label: {
                Text("Повторить")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }
        }
    }

    // MARK: - Content

    private func contentView(_ course: Course) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 40) {
                // Hero
                heroSection
                
                // Progress
                progressSection
                
                // Weeks
                ForEach(course.modules.sorted { $0.order < $1.order }) { module in
                    WeekSection(module: module, viewModel: viewModel)
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, hPad)
            .padding(.top, 16)
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Image
            Image("restore_cover")
                .resizable()
                .scaledToFill()
                .frame(height: 280)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.85), .black.opacity(0.3), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )

            // Text
            VStack(alignment: .leading, spacing: 8) {
                Text("RE:STORE")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(-0.5)

                Text("Программа восстановления тазового дна")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
    
    // MARK: - Progress
    
    private var progressSection: some View {
        let total = max(viewModel.totalLessons, 1)
        let completed = viewModel.completedLessons
        let percent = Int((Double(completed) / Double(total)) * 100)
        
        return HStack(spacing: 20) {
            // Ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 3)
                
                Circle()
                    .trim(from: 0, to: CGFloat(completed) / CGFloat(total))
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Text("\(percent)%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 52, height: 52)
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text("Прогресс")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("\(completed) из \(total) уроков")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }
}

// MARK: - Week Section

private struct WeekSection: View {
    let module: Module
    @ObservedObject var viewModel: ProgramViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                Text(String(format: "%02d", module.order))
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(-2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(module.title.isEmpty ? "Неделя \(module.order)" : module.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("\(lessonCount) уроков")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.35))
                }
                
                Spacer()
                
                // Completion
                if completedCount == lessonCount && lessonCount > 0 {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.green)
                }
            }

            // Lessons
            LessonsGrid(module: module, viewModel: viewModel)
        }
    }
    
    private var lessonCount: Int {
        module.days.flatMap { $0.lessons }.count
    }
    
    private var completedCount: Int {
        module.days.flatMap { $0.lessons }
            .filter { viewModel.getLessonState($0.id) == .completed }
            .count
    }
}

// MARK: - Lessons Grid (Horizontal)

private struct LessonsGrid: View {
    let module: Module
    @ObservedObject var viewModel: ProgramViewModel
    @State private var selectedLesson: Lesson?

    private var allLessons: [(Lesson, String)] {
        module.days
            .sorted { $0.order < $1.order }
            .flatMap { day in
                day.lessons
                    .sorted { $0.order < $1.order }
                    .map { ($0, day.title) }
            }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(allLessons, id: \.0.id) { lesson, dayTitle in
                    LessonCard(
                        lesson: lesson,
                        dayTitle: dayTitle,
                        state: viewModel.getLessonState(lesson.id),
                        onTap: {
                            haptic()
                            if lesson.locked {
                                viewModel.showLocked(lesson)
                                return
                            }
                            selectedLesson = lesson
                        }
                    )
                }
            }
            .padding(.vertical, 2)
        }
        .scrollClipDisabled()
        .fullScreenCover(item: $selectedLesson) { lesson in
            LessonDetailView(lesson: lesson)
        }
    }
    
    private func haptic() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

// MARK: - Lesson Card

private struct LessonCard: View {
    let lesson: Lesson
    let dayTitle: String
    let state: LessonState
    let onTap: () -> Void

    private let cardWidth: CGFloat = 200
    private let cardHeight: CGFloat = 240

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottom) {
                // Background
                backgroundLayer
                
                // Gradient overlay for readability
                LinearGradient(
                    colors: [.black.opacity(0.9), .black.opacity(0.3), .clear],
                    startPoint: .bottom,
                    endPoint: .center
                )
                
                // Content
                // Content
                contentLayer

                if lesson.locked {
                    // затемнение
                    Color.black.opacity(0.55)

                    // ЛОК-ПАНЕЛЬ СВЕРХУ
                    VStack {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.92))

                            Text(lockText)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.92))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                        .padding(.top, 12)
                        .padding(.horizontal, 12)

                        Spacer()
                    }
                }
            }
            .frame(width: cardWidth, height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(borderColor, lineWidth: state == .completed ? 1 : 0.5)
            )
        }
        .buttonStyle(CardPressStyle())
        .disabled(lesson.locked)
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private var backgroundLayer: some View {
        if let url = lesson.thumbnailURL, let imageURL = URL(string: url) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: cardWidth, height: cardHeight)
                        .clipped()
                case .failure, .empty:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }
    
    private var placeholder: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color(white: 0.12), Color(white: 0.06)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
    
    private var lockText: String {
        if let s = lesson.unlockDate,
           let d = ISO8601DateFormatter().date(from: s) {
            let f = DateFormatter()
            f.locale = Locale(identifier: "ru_RU")
            f.dateFormat = "d MMM"
            return "Доступ с \(f.string(from: d))"
        }
        return "Скоро откроется"
    }
    
    // MARK: - Content Layer
    
    private var contentLayer: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Status badge - top left
            HStack {
                statusBadge
                Spacer()
            }
            .padding(12)
            
            Spacer()
            
            // Info - bottom
            VStack(alignment: .leading, spacing: 8) {
                Text(dayTitle.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1)
                
                Text(lesson.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 9, weight: .medium))
                    Text(formatDuration(lesson.duration))
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.45))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Status Badge
    
    private var statusBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(badgeBackground)
                .frame(width: 26, height: 26)
            
            Image(systemName: badgeIcon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(badgeColor)
        }
    }
    
    private var badgeIcon: String {
        switch state {
        case .completed: return "checkmark"
        case .inProgress: return "play.fill"
        case .notStarted: return "play.fill"
        }
    }
    
    private var badgeColor: Color {
        switch state {
        case .completed: return .green
        case .inProgress: return .white
        case .notStarted: return .white.opacity(0.5)
        }
    }
    
    private var badgeBackground: Color {
        switch state {
        case .completed: return .green.opacity(0.2)
        case .inProgress: return .white.opacity(0.15)
        case .notStarted: return .white.opacity(0.08)
        }
    }
    
    private var borderColor: Color {
        switch state {
        case .completed: return .green.opacity(0.3)
        case .inProgress: return .white.opacity(0.15)
        case .notStarted: return .white.opacity(0.06)
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let mins = max(1, seconds / 60)
        return "\(mins) мин"
    }
}

// MARK: - Card Press Style

private struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    ProgramView()
}
