//
//  HomeView.swift
//  PelvicFloorApp
//
//  Premium Home — Full Logic + Neon Meditations + New Quick Actions
//

import SwiftUI
import AVFoundation
import Combine
import SafariServices
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Models

struct MeditationItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let duration: String
    let category: String
    let icon: String
    let audioFileName: String
    let benefits: [String]
    let fullDescription: String
}

struct TheoryLesson: Identifiable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let duration: String
    let youtubeURL: String
    let thumbnailGradient: [Color]
    let category: String
    let thumbnailGif: String
}

// MARK: - Home View

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var appState: AppState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @State private var isAffirmationMagicPresented = false
    @State private var selectedMeditation: MeditationItem? = nil
    @State private var safariURL: URL? = nil
    @State private var selectedLessonToPlay: Lesson? = nil
    @State private var showProfileSheet = false
    @State private var profileDetent: PresentationDetent = .height(460)
    
    
    @StateObject private var audioPlayer = AudioMeditationPlayer()

    private var isIPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }

    private var adaptiveHPad: CGFloat { isIPad ? 28 : 16 }
    private var adaptiveHeroHeight: CGFloat { isIPad ? 340 : 260 }
    private var compactDetent: PresentationDetent { .height(isIPad ? 500 : 430) }
    private var expandedDetent: PresentationDetent { .height(isIPad ? 640 : 560) }

    

    private var meditations: [MeditationItem] {
        [
            .init(
                title: "Вечерняя",
                subtitle: "Отпустить день",
                duration: "6 мин",
                category: "Сон",
                icon: "moon.stars.fill",
                audioFileName: "med_03.mp3",
                benefits: ["Замедление", "Расслабление", "Отпускание напряжения", "Подготовка ко сну", "Покой"],
                fullDescription: """
    После насыщенного дня мысли продолжают крутиться, тело остаётся в напряжении, а ум не сразу переходит в режим отдыха. Даже при усталости бывает сложно по-настоящему расслабиться и уснуть.

    Эта практика создана для мягкого перехода из активности в покой. Здесь не нужно контролировать, анализировать или стараться уснуть — достаточно замедлиться, выдохнуть и отпустить прошедший день.
    """
            ),
            .init(
                title: "Принятие тела",
                subtitle: "Контакт и опора",
                duration: "5 мин",
                category: "Любовь",
                icon: "heart.fill",
                audioFileName: "med_02.mp3",
                benefits: ["Контакт с телом", "Принятие", "Безопасность", "Опора", "Спокойствие"],
                fullDescription: """
    Мы часто живём «в голове» — оцениваем, сравниваем и требуем от тела больше, чем оно может дать. В такие моменты тело перестаёт быть домом и становится объектом контроля или недовольства.

    Эта практика помогает вернуться в телесные ощущения, услышать сигналы и почувствовать опору внутри себя. Здесь не нужно ничего менять или исправлять — только позволить себе быть и принимать тело таким, какое оно есть сейчас.
    """
            ),
            .init(
                title: "Утренняя",
                subtitle: "Ясность",
                duration: "3 мин",
                category: "Старт",
                icon: "sunrise.fill",
                audioFileName: "med_01.mp3",
                benefits: ["Мягкое пробуждение", "Ясность", "Фокус", "Опора", "Присутствие"],
                fullDescription: """
    Мы часто начинаем утро на автопилоте — с мыслей о делах, ожиданиях и внешнем шуме, не успев почувствовать себя и своё состояние.

    Эта практика помогает вернуться в тело, дыхание и настоящий момент, чтобы начать день без спешки — с ясностью, вниманием и ощущением внутренней опоры.
    """
            )
        ]
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.isLoading {
                loadingView
            } else {
                mainContent
            }
        }
        .task {
            await viewModel.initialLoad()
        }
        .sheet(isPresented: $showProfileSheet) {
            ProfileSheetContainer(isExpanded: profileDetent == expandedDetent) {
                ProfileView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, (profileDetent == .height(isIPad ? 640 : 560)) ? 10 : 0)
            }
            .presentationDetents([compactDetent, expandedDetent], selection: $profileDetent)
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(26)
            .presentationBackground(.clear)
            .onAppear { profileDetent = compactDetent }
        }
        .fullScreenCover(isPresented: $isAffirmationMagicPresented) {
            AffirmationMagicView { isAffirmationMagicPresented = false }
        }
        .fullScreenCover(item: $selectedMeditation) { item in
            MeditationPlayerView(item: item, audioPlayer: audioPlayer)
        }
        .fullScreenCover(item: $selectedLessonToPlay) { lesson in
            LessonDetailView(lesson: lesson)
                .environmentObject(FullscreenManager.shared)
        }
        .fullScreenCover(item: Binding(
            get: { safariURL.map { SafariItem(url: $0) } },
            set: { safariURL = $0?.url }
        )) { item in
            SafariView(url: item.url).ignoresSafeArea()
        }
        .onDisappear { audioPlayer.stop() }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(.white.opacity(0.6))
                .scaleEffect(0.9)
            Text("Загружаем...")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                topBar
                    .padding(.horizontal, adaptiveHPad)

                heroCard
                    .padding(.horizontal, adaptiveHPad)

                quickActionsRow

                theorySection

                meditationsSection

                Spacer(minLength: 100)
            }
            .padding(.top, 0)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text(greetingTitle)
                    .font(.system(size: isIPad ? 22 : 20, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .kerning(-0.2)
            }

            Spacer()

            Button {
                haptic(.light)
                showProfileSheet = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 40, height: 40)

                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                }
                .frame(width: 52, height: 52)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
        .zIndex(50)
    }


    private var greetingTitle: String {
        let name = appState.currentUser?.displayName ?? ""
        return name.isEmpty ? "Привет" : "Привет, \(name)"
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        let total = max(viewModel.totalLessons, 1)
        let done = max(viewModel.completedLessons, 0)
        let progress = CGFloat(done) / CGFloat(total)
        let hasProgress = done > 0

        return ZStack(alignment: .bottomLeading) {
            // Background image
            Image("seza_hero")
                .resizable()
                .scaledToFill()
                .frame(height: adaptiveHeroHeight)
                .offset(y: 35)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.8), .black.opacity(0.3), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))


            // Content
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Spacer()
                    ProgressRing(progress: progress, size: 44)
                }

                Spacer()

                Text("RE:STORE")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Text("Восстановление через движение")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)

                // Buttons
                HStack(spacing: 10) {
                    Button {
                        haptic(.medium)
                        if let lesson = viewModel.nextLesson {
                            selectedLessonToPlay = lesson
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text(hasProgress ? "Продолжить" : "Начать")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(18)
        }
        .frame(height: adaptiveHeroHeight)
    }

    // MARK: - Quick Actions (без Программы, добавлены Дневники)

    private var quickActionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button {
                    haptic(.medium)
                    isAffirmationMagicPresented = true
                } label: {
                    QuickActionCard(icon: "sparkles", title: "Послание", color: .purple)
                }
                .buttonStyle(ScaleButtonStyle())

                NavigationLink { CenterPracticeView() } label: {
                    QuickActionCard(icon: "wind", title: "Дыхание", color: .cyan)
                }
                .buttonStyle(ScaleButtonStyle())

                NavigationLink { GratitudeJournalView() } label: {
                    QuickActionCard(icon: "heart.text.square.fill", title: "Благодарность", color: .pink)
                }
                .buttonStyle(ScaleButtonStyle())

                NavigationLink { StateTrackerView() } label: {
                    QuickActionCard(icon: "waveform.path.ecg", title: "Состояние", color: .green)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.vertical, 2)
            .padding(.leading, adaptiveHPad)
            .padding(.trailing, 8)
        }
    }

    // MARK: - Theory Section

    private var theorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Теория")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                NavigationLink {
                    AllTheoryLessonsView(lessons: viewModel.theoryLessons) { lesson in
                        safariURL = URL(string: lesson.youtubeURL)
                    }
                } label: {
                    Text("Все")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, adaptiveHPad) // ✅ только заголовок

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.theoryLessons.prefix(5)) { lesson in
                        Button {
                            haptic(.medium)
                            safariURL = URL(string: lesson.youtubeURL)
                        } label: {
                            TheoryCard(lesson: lesson)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.vertical, 2)
                .padding(.leading, adaptiveHPad)
                .padding(.trailing, 8)
            }
        }
    }

    // MARK: - Meditations Section

    private var meditationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Медитации")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text("\(meditations.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
            }
            .padding(.horizontal, adaptiveHPad) // ✅ только заголовок

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(meditations) { item in
                        Button {
                            haptic(.medium)
                            selectedMeditation = item
                        } label: {
                            MeditationCard(
                                item: item,
                                isPlaying: audioPlayer.nowPlayingID == item.id && audioPlayer.isPlaying
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.vertical, 18)
                .padding(.leading, adaptiveHPad)
                .padding(.trailing, 8)
            }
        }
    }

    // MARK: - Helpers

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Scale Button Style

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Progress Ring

private struct ProgressRing: View {
    let progress: CGFloat
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 3)

            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(Int(min(progress, 1) * 100))%")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Quick Action Card

private struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }

            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
        }
        .frame(width: 85, height: 90)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Theory Card (Minimalist)

private struct TheoryCard: View {
    let lesson: TheoryLesson

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: lesson.thumbnailGradient + [Color.black.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(lesson.duration)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.black.opacity(0.3)))

                    Spacer()

                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                Text(lesson.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(lesson.subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
            .padding(14)
        }
        .frame(width: 160, height: 120)
    }
}

// MARK: - Meditation Card (Neon Style)

private struct MeditationCard: View {
    let item: MeditationItem
    let isPlaying: Bool

    private var neonColor: Color {
        switch item.icon {
        case "moon.stars.fill": return Color(red: 0.6, green: 0.4, blue: 1.0)
        case "heart.fill": return Color(red: 1.0, green: 0.4, blue: 0.6)
        case "sunrise.fill": return Color(red: 1.0, green: 0.7, blue: 0.3)
        default: return .white
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    neonColor.opacity(isPlaying ? 0.8 : 0.4),
                                    neonColor.opacity(0.1),
                                    neonColor.opacity(isPlaying ? 0.6 : 0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isPlaying ? 2 : 1.5
                        )
                )
                .shadow(color: neonColor.opacity(isPlaying ? 0.4 : 0.2), radius: isPlaying ? 20 : 12, x: 0, y: 8)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [neonColor.opacity(0.08), .clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 150
                    )
                )

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(neonColor.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: item.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(neonColor)
                    }

                    Spacer()

                    if isPlaying {
                        Image(systemName: "waveform")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(neonColor)
                    }
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    Text(item.subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }

                HStack {
                    Text(item.duration)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(neonColor.opacity(0.9))

                    Spacer()

                    Image(systemName: "headphones")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(16)
        }
        .frame(width: 170, height: 160)
    }
}

// MARK: - Safari Helpers

private struct SafariItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true

        let vc = SFSafariViewController(url: url, configuration: config)
        vc.preferredBarTintColor = .black
        vc.preferredControlTintColor = .white
        vc.dismissButtonStyle = .close
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - All Theory Lessons View

struct AllTheoryLessonsView: View {
    let lessons: [TheoryLesson]
    let onLessonTap: (TheoryLesson) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(lessons) { lesson in
                        Button {
                            onLessonTap(lesson)
                        } label: {
                            TheoryGridCard(lesson: lesson)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("Теория")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct TheoryGridCard: View {
    let lesson: TheoryLesson

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: lesson.thumbnailGradient + [Color.black.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(lesson.duration)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.black.opacity(0.35)))

                    Spacer()

                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                Text(lesson.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(lesson.subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(14)
        }
        .frame(height: 140)
    }
}

private struct ProfileSheetContainer<Content: View>: View {
    let isExpanded: Bool
    let content: Content

    init(isExpanded: Bool, @ViewBuilder content: () -> Content) {
        self.isExpanded = isExpanded
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            RadialGradient(
                colors: [Color.cyan.opacity(0.10), Color.clear],
                center: .top,
                startRadius: 40,
                endRadius: 420
            )
            .ignoresSafeArea()
            .offset(y: -160)

            RadialGradient(
                colors: [Color.purple.opacity(0.08), Color.clear],
                center: .bottom,
                startRadius: 120,
                endRadius: 620
            )
            .ignoresSafeArea()

            VStack(spacing: 8) {
                Capsule()
                    .fill(Color.white.opacity(0.16))
                    .frame(width: 46, height: 5)
                    .padding(.top, isExpanded ? 14 : 8)

                content
                    .padding(.top, isExpanded ? 6 : 2)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 0)
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AppState())
    }
}
