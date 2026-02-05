//
//  LessonDetailView.swift
//  PelvicFloorApp
//
//  Premium Lesson View — Spacing Polished (iOS 16+)
//

import SwiftUI
import AVKit

struct LessonDetailView: View {
    let lesson: Lesson

    @EnvironmentObject private var fullscreenManager: FullscreenManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: VideoPlayerViewModel
    @State private var hasAppeared = false
    @State private var reporter: LessonProgressReporter? = nil
    @State private var localTickTask: Task<Void, Never>? = nil

    private let topExtraOffset: CGFloat = -64
    private let sidePadding: CGFloat = 18
    private let cornerRadius: CGFloat = 18

    init(lesson: Lesson) {
        self.lesson = lesson
        _viewModel = StateObject(wrappedValue: VideoPlayerViewModel(lesson: lesson))
    }

    var body: some View {
        GeometryReader { geo in
            let safeTop = geo.safeAreaInsets.top
            let safeBottom = geo.safeAreaInsets.bottom
            let headerTop = max(-24, safeTop + topExtraOffset)
            let videoHeight = max(260, geo.size.height * 0.48)

            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.black, Color(white: 0.06)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Video
                    videoSection
                        .frame(height: videoHeight)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                        .padding(.horizontal, sidePadding)
                        .padding(.top, headerTop)
                        .padding(.bottom, 14)

                    // Info
                    infoSection(safeBottom: safeBottom)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                // Top Controls
                topControls(paddedTop: headerTop)
                    .zIndex(10)

                // Fullscreen overlay ABOVE this screen (fixes .fullScreenCover layering)
                if fullscreenManager.isFullscreen,
                   let vm = fullscreenManager.videoPlayerViewModel {
                    FullscreenVideoOverlay(viewModel: vm) {
                        fullscreenManager.exitFullscreen()
                    }
                    .transition(.opacity)
                    .zIndex(9999)
                }
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(false)
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            ProgressService.shared.markLessonStarted(lesson.id)

            Task {
                try? await Task.sleep(nanoseconds: 120_000_000)
                await viewModel.loadVideo()

                if reporter == nil {
                    reporter = LessonProgressReporter(lessonId: lesson.id)
                    reporter?.start {
                        Int(viewModel.currentTime.rounded(.down))
                    }
                }

                localTickTask?.cancel()
                localTickTask = Task {
                    while !Task.isCancelled {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        let sec = max(0, Int(viewModel.currentTime))
                        await MainActor.run {
                            ProgressService.shared.updateLessonPosition(lesson.id, position: Double(sec))
                        }
                    }
                }
            }
        }
        .onDisappear {
            // если уходим в fullscreen — НЕ убиваем плеер
            guard !fullscreenManager.isFullscreen else { return }

            localTickTask?.cancel()
            localTickTask = nil

            let finalSec = max(0, Int(min(viewModel.currentTime, viewModel.duration)))
            reporter?.stop()
            Task { await ProgressSyncService.shared.pushHeartbeat(lessonId: lesson.id, seconds: finalSec) }

            reporter = nil
            viewModel.cleanup()
        }

        .onChange(of: viewModel.isCompleted) { _, completed in
            guard completed else { return }

            ProgressService.shared.markLessonCompleted(lesson.id)
            let finalSec = max(0, Int(min(viewModel.currentTime, viewModel.duration)))
            reporter?.complete(finalSeconds: finalSec)
        }

    }

    // MARK: - Video Section

    @ViewBuilder
    private var videoSection: some View {
        ZStack {
            Color.black

            switch viewModel.state {
            case .loading:
                VStack(spacing: 14) {
                    ProgressView()
                        .tint(.white.opacity(0.75))
                        .scaleEffect(1.05)

                    Text("Загрузка…")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                }
                .padding(.top, 6)

            case .ready:
                VideoPlayerContent(viewModel: viewModel)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

            case .error(let message):
                VStack(spacing: 18) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 34, weight: .thin))
                        .foregroundColor(.white.opacity(0.55))

                    Text(message)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.62))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 26)

                    Button {
                        Task { await viewModel.loadVideo() }
                    } label: {
                        Text("Повторить")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
                .padding(.top, 6)
            }
        }
    }

    // MARK: - Top Controls

    private func topControls(paddedTop: CGFloat) -> some View {
        VStack {
            HStack(spacing: 12) {
                Button {
                    haptic(.light)
                    dismiss()
                } label: {
                    ZStack {
                        Circle().fill(.ultraThinMaterial)
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 38, height: 38)
                }

                Spacer()

                AirPlayButton()
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .padding(.horizontal, sidePadding)
            .padding(.top, paddedTop)

            Spacer()
        }
        .allowsHitTesting(!fullscreenManager.isFullscreen)
    }

    // MARK: - Info Section

    private func infoSection(safeBottom: CGFloat) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                headerBlock

                Divider()
                    .overlay(Color.white.opacity(0.08))

                aboutBlock
            }
            .padding(.horizontal, sidePadding)
            .padding(.top, 18)
            .padding(.bottom, max(24, safeBottom + 22))
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(white: 0.07))
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(
            VStack(spacing: 0) {
                // subtle top separator to make the "sheet" feel premium
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1)
                Spacer()
            }
        )
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            if viewModel.isCompleted {
                HStack(spacing: 7) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("ПРОЙДЕНО")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.2)
                }
                .foregroundColor(.green)
                .padding(.bottom, 2)
            }

            Text(lesson.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 14) {
                Label("\(max(1, lesson.duration / 60)) мин", systemImage: "clock")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))

                if viewModel.duration > 0 {
                    Label("\(Int(viewModel.duration / 60)) мин видео", systemImage: "play.rectangle")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
        }
    }

    private var aboutBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("О практике")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.45))
                .tracking(1.2)

            Text(lesson.description.isEmpty ? "Описание отсутствует" : lesson.description)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.84))
                .lineSpacing(6)

            if let notes = lesson.notes, !notes.isEmpty {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.yellow)

                    Text(notes)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.78))
                        .lineSpacing(4)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.yellow.opacity(0.09))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
            }
        }
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Video Player Content

private struct VideoPlayerContent: View {
    @ObservedObject var viewModel: VideoPlayerViewModel
    @EnvironmentObject var fullscreenManager: FullscreenManager
    @State private var showControls = true
    @State private var hideTask: Task<Void, Never>?
    @State private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let player = viewModel.player {
                    VideoLayer(player: player)
                        .contentShape(Rectangle())
                        .onTapGesture { toggleControls() }
                } else {
                    Color.black
                }

                if viewModel.isBuffering {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.1)
                }

                if showControls {
                    controlsOverlay(size: geo.size)
                        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                }
            }
        }
        .onChange(of: viewModel.isPlaying) { _, playing in
            if playing && showControls && !isDragging { scheduleHide() }
        }
        .onDisappear { hideTask?.cancel() }
    }

    private func controlsOverlay(size: CGSize) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color.black.opacity(0.45), .clear, Color.black.opacity(0.65)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack {
                Spacer()

                Button {
                    haptic(.medium)
                    viewModel.togglePlayPause()
                    scheduleHide()
                } label: {
                    ZStack {
                        Circle().fill(.ultraThinMaterial)
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundColor(.white)
                            .offset(x: viewModel.isPlaying ? 0 : 1)
                    }
                    .frame(width: 76, height: 76)
                }
                .offset(y: size.height * 0.08)

                Spacer()

                VStack(spacing: 10) {
                    ProgressBar(
                        current: viewModel.currentTime,
                        duration: viewModel.duration,
                        isDragging: $isDragging
                    ) { time, scrubbing in
                        if scrubbing { hideTask?.cancel() } else { scheduleHide() }
                        viewModel.seek(to: time, isScrubbing: scrubbing)
                    }

                    HStack {
                        Text(formatTime(viewModel.currentTime))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                            .monospacedDigit()

                        Spacer()

                        HStack(spacing: 26) {
                            Button {
                                haptic(.light)
                                viewModel.seek(to: viewModel.currentTime - 10, isScrubbing: false)
                                scheduleHide()
                            } label: {
                                Image(systemName: "gobackward.10")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            Button {
                                haptic(.light)
                                viewModel.seek(to: viewModel.currentTime + 10, isScrubbing: false)
                                scheduleHide()
                            } label: {
                                Image(systemName: "goforward.10")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }

                        Spacer()

                        HStack(spacing: 10) {
                            Text(formatTime(viewModel.duration))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.55))
                                .monospacedDigit()

                            Button {
                                haptic(.light)
                                fullscreenManager.enterFullscreen(with: viewModel)
                            } label: {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding(.leading, 2)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
    }

    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.18)) { showControls.toggle() }
        if showControls { scheduleHide() }
    }

    private func scheduleHide() {
        hideTask?.cancel()
        guard viewModel.isPlaying && !isDragging else { return }

        hideTask = Task {
            try? await Task.sleep(nanoseconds: 3_200_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.22)) { showControls = false }
            }
        }
    }

    private func formatTime(_ sec: Double) -> String {
        guard sec.isFinite && !sec.isNaN else { return "0:00" }
        let s = Int(max(0, sec))
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Video Layer

private struct VideoLayer: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> UIView {
        let view = PlayerLayerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let v = uiView as? PlayerLayerView else { return }
        if v.playerLayer.player !== player { v.playerLayer.player = player }
    }

    private final class PlayerLayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .black
        }
        required init?(coder: NSCoder) { fatalError() }
    }
}

// MARK: - Progress Bar

private struct ProgressBar: View {
    let current: Double
    let duration: Double
    @Binding var isDragging: Bool
    let onSeek: (Double, Bool) -> Void

    @State private var dragValue: CGFloat = 0

    private var progress: CGFloat {
        guard duration > 0 else { return 0 }
        return isDragging ? dragValue : CGFloat(current / duration)
    }

    var body: some View {
        GeometryReader { geo in
            let p = min(max(progress, 0), 1)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.white.opacity(0.22))
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.white.opacity(0.95))
                    .frame(width: geo.size.width * p, height: 4)

                Circle()
                    .fill(Color.white)
                    .frame(width: isDragging ? 16 : 12, height: isDragging ? 16 : 12)
                    .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)
                    .offset(x: geo.size.width * p - (isDragging ? 8 : 6))
                    .animation(.easeOut(duration: 0.12), value: isDragging)
            }
            .frame(height: 24)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        isDragging = true
                        let pct = min(max(v.location.x / max(1, geo.size.width), 0), 1)
                        dragValue = pct
                        onSeek(Double(pct) * duration, true)
                    }
                    .onEnded { v in
                        let pct = min(max(v.location.x / max(1, geo.size.width), 0), 1)
                        onSeek(Double(pct) * duration, false)
                        isDragging = false
                    }
            )
        }
        .frame(height: 24)
    }
}

#Preview {
    LessonDetailView(
        lesson: Lesson(
            id: "1",
            title: "Введение в практику",
            description: "Первый урок программы с детальным описанием всех упражнений и техник выполнения.",
            type: .video,
            duration: 360,
            videoURL: nil,
            thumbnailURL: nil,
            notes: "Важно: выполняйте упражнения медленно и осознанно",
            order: 1,
            isLocked: false,
            unlockDate: nil
        )
    )
    .environmentObject(FullscreenManager.shared)
}
