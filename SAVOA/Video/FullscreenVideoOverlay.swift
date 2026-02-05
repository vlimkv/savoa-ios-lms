//
//  FullscreenVideoOverlay.swift
//  PelvicFloorApp
//
//  Fullscreen video overlay with controls
//

import SwiftUI
import AVKit

struct FullscreenVideoOverlay: View {
    @ObservedObject var viewModel: VideoPlayerViewModel
    let onClose: () -> Void
    
    @State private var hideControlsTask: Task<Void, Never>?
    @State private var isDraggingProgress = false
    @State private var isClosing = false
    
    var body: some View {
        GeometryReader { geometry in
            let isPortrait = geometry.size.height > geometry.size.width
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Video layer
                if let player = viewModel.player {
                    VideoLayerView(player: player)
                        .ignoresSafeArea()
                        .offset(y: isPortrait ? -12 : 0)
                        .onTapGesture { toggleControls() }
                }
                
                // Buffering
                if viewModel.isBuffering {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.3)
                }
                
                // Controls
                if viewModel.showControls {
                    controlsOverlay(safeArea: geometry.safeAreaInsets, isPortrait: isPortrait)
                        .transition(.opacity.animation(.easeInOut(duration: 0.25)))
                }
            }
        }
        .statusBarHidden(true)
        .onChange(of: viewModel.isPlaying) { _, isPlaying in
            if isPlaying && viewModel.showControls && !isDraggingProgress {
                scheduleHideControls()
            }
        }
        .onDisappear {
            hideControlsTask?.cancel()
        }
    }
    
    // MARK: - Controls Overlay
    
    private func controlsOverlay(safeArea: EdgeInsets, isPortrait: Bool) -> some View {
        ZStack {
            // Gradient
            LinearGradient(
                colors: [
                    Color.black.opacity(0.6),
                    Color.clear,
                    Color.clear,
                    Color.black.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                topBar(safeTop: safeArea.top)

                Spacer()

                centerControls(isPortrait: isPortrait)
                    .offset(y: isPortrait ? 0 : 36)

                Spacer()

                bottomControls(safeBottom: safeArea.bottom, isPortrait: isPortrait)
                    .offset(y: isPortrait ? 0 : 28)
            }
            .padding(.top, isPortrait ? -48 : 0)
        }
    }
    
    // MARK: - Top Bar
    
    private func topBar(safeTop: CGFloat) -> some View {
        HStack {
            Button {
                guard !isClosing else { return }
                isClosing = true
                haptic(.soft)

                viewModel.cleanup()
                onClose()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .disabled(isClosing)
            
            Spacer()
            
            AirPlayButton()
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, max(safeTop + 8, 16))
    }
    
    // MARK: - Center Controls
    
    private func centerControls(isPortrait: Bool) -> some View {
        Group {
            if isPortrait {
                // ПОРТРЕТ — как было
                HStack(spacing: 50) {
                    Button {
                        haptic(.light)
                        viewModel.seek(to: viewModel.currentTime - 10, isScrubbing: false)
                        scheduleHideControls()
                    } label: {
                        Image(systemName: "gobackward.10")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(.white)
                    }

                    Button {
                        haptic(.medium)
                        viewModel.togglePlayPause()
                        scheduleHideControls()
                    } label: {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 80, weight: .medium))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
                    }

                    Button {
                        haptic(.light)
                        viewModel.seek(to: viewModel.currentTime + 10, isScrubbing: false)
                        scheduleHideControls()
                    } label: {
                        Image(systemName: "goforward.10")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            } else {
                // ЛАНДШАФТ — левый край / центр / правый край
                HStack {
                    Button {
                        haptic(.light)
                        viewModel.seek(to: viewModel.currentTime - 10, isScrubbing: false)
                        scheduleHideControls()
                    } label: {
                        Image(systemName: "gobackward.10")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Button {
                        haptic(.medium)
                        viewModel.togglePlayPause()
                        scheduleHideControls()
                    } label: {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 74, weight: .medium))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
                    }

                    Spacer()

                    Button {
                        haptic(.light)
                        viewModel.seek(to: viewModel.currentTime + 10, isScrubbing: false)
                        scheduleHideControls()
                    } label: {
                        Image(systemName: "goforward.10")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 56)
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Bottom Controls
    
    private func bottomControls(safeBottom: CGFloat, isPortrait: Bool) -> some View {
        VStack(spacing: 16) {
            // Progress bar
            FullscreenProgressBar(
                currentTime: viewModel.currentTime,
                duration: viewModel.duration,
                isDragging: $isDraggingProgress,
                onSeek: { time, scrubbing in
                    if scrubbing {
                        hideControlsTask?.cancel()
                    } else {
                        scheduleHideControls()
                    }
                    viewModel.seek(to: time, isScrubbing: scrubbing)
                }
            )
            
            // Time
            HStack {
                Text(formatTime(viewModel.currentTime))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .monospacedDigit()
                
                Spacer()
                
                Text(formatTime(viewModel.duration))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, max(safeBottom + (isPortrait ? 34 : 10), isPortrait ? 44 : 18))
    }
    
    // MARK: - Helpers
    
    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.25)) {
            viewModel.showControls.toggle()
        }
        if viewModel.showControls {
            scheduleHideControls()
        }
    }
    
    private func scheduleHideControls() {
        hideControlsTask?.cancel()
        
        guard viewModel.isPlaying && !isDraggingProgress else { return }
        
        hideControlsTask = Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    viewModel.showControls = false
                }
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && !seconds.isNaN else { return "0:00" }
        let total = Int(max(0, seconds))
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Video Layer View

private struct VideoLayerView: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> UIView {
        let view = PlayerLayerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let layerView = uiView as? PlayerLayerView else { return }
        if layerView.playerLayer.player !== player {
            layerView.playerLayer.player = player
        }
    }
    
    private class PlayerLayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .black
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

// MARK: - Fullscreen Progress Bar

private struct FullscreenProgressBar: View {
    let currentTime: Double
    let duration: Double
    @Binding var isDragging: Bool
    let onSeek: (Double, Bool) -> Void
    
    @State private var dragProgress: CGFloat = 0
    
    private var progress: CGFloat {
        guard duration > 0 else { return 0 }
        return isDragging ? dragProgress : CGFloat(currentTime / duration)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.white.opacity(0.25))
                    .frame(height: 5)
                
                // Progress
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.white)
                    .frame(width: geometry.size.width * min(max(progress, 0), 1), height: 5)
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: isDragging ? 20 : 16, height: isDragging ? 20 : 16)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .offset(x: (geometry.size.width * min(max(progress, 0), 1)) - (isDragging ? 10 : 8))
                    .animation(.easeOut(duration: 0.1), value: isDragging)
            }
            .frame(height: 32)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let percent = min(max(value.location.x / geometry.size.width, 0), 1)
                        dragProgress = percent
                        onSeek(Double(percent) * duration, true)
                    }
                    .onEnded { value in
                        let percent = min(max(value.location.x / geometry.size.width, 0), 1)
                        onSeek(Double(percent) * duration, false)
                        isDragging = false
                    }
            )
        }
        .frame(height: 32)
    }
}
