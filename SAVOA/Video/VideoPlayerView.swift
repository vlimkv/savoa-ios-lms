//
//  VideoPlayerView.swift
//  PelvicFloorApp
//
//  Premium Video Player — Stable & Beautiful
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @ObservedObject var viewModel: VideoPlayerViewModel
    
    @State private var hideControlsTask: Task<Void, Never>?
    @State private var isDraggingProgress = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Video layer
                if let player = viewModel.player {
                    VideoLayer(player: player)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleControls()
                        }
                } else {
                    Color.black
                }
                
                // Buffering indicator
                if viewModel.isBuffering {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                }
                
                // Controls overlay
                if viewModel.showControls {
                    ControlsOverlay(
                        viewModel: viewModel,
                        safeArea: geometry.safeAreaInsets,
                        isDraggingProgress: $isDraggingProgress,
                        onSeekStarted: { cancelHideControls() },
                        onSeekEnded: { scheduleHideControls() },
                        onPlayPause: { scheduleHideControls() }
                    )
                    .transition(.opacity.animation(.easeInOut(duration: 0.25)))
                }
            }
        }
        .background(Color.black)
        .onChange(of: viewModel.isPlaying) { _, isPlaying in
            if isPlaying && viewModel.showControls && !isDraggingProgress {
                scheduleHideControls()
            }
        }
        .onDisappear {
            hideControlsTask?.cancel()
        }
    }
    
    // MARK: - Controls Logic
    
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
    
    private func cancelHideControls() {
        hideControlsTask?.cancel()
    }
}

// MARK: - Video Layer

private struct VideoLayer: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        view.backgroundColor = .black
        return view
    }
    
    func updateUIView(_ uiView: PlayerView, context: Context) {
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
    }
}

private final class PlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

// MARK: - Controls Overlay

private struct ControlsOverlay: View {
    @ObservedObject var viewModel: VideoPlayerViewModel
    let safeArea: EdgeInsets
    @Binding var isDraggingProgress: Bool
    let onSeekStarted: () -> Void
    let onSeekEnded: () -> Void
    let onPlayPause: () -> Void
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color.black.opacity(0.5),
                    Color.clear,
                    Color.clear,
                    Color.black.opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                topBar
                Spacer()
                centerControls
                Spacer()
                bottomControls
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            Spacer()
            AirPlayButton()
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, max(safeArea.top + 8, 16))
    }
    
    // MARK: - Center Controls
    
    private var centerControls: some View {
        HStack(spacing: 50) {
            // Rewind 10s
            Button {
                haptic(.light)
                viewModel.seek(to: viewModel.currentTime - 10, isScrubbing: false)
                onPlayPause()
            } label: {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // Play/Pause
            Button {
                haptic(.medium)
                viewModel.togglePlayPause()
                onPlayPause()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 72, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
            }
            
            // Forward 10s
            Button {
                haptic(.light)
                viewModel.seek(to: viewModel.currentTime + 10, isScrubbing: false)
                onPlayPause()
            } label: {
                Image(systemName: "goforward.10")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Progress bar
            ProgressBar(
                currentTime: viewModel.currentTime,
                duration: viewModel.duration,
                isDragging: $isDraggingProgress,
                onSeek: { time, scrubbing in
                    if scrubbing {
                        onSeekStarted()
                    } else {
                        onSeekEnded()
                    }
                    viewModel.seek(to: time, isScrubbing: scrubbing)
                }
            )
            
            // Time labels
            HStack {
                Text(formatTime(viewModel.currentTime))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .monospacedDigit()
                
                Spacer()
                
                Text(formatTime(viewModel.duration))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, max(safeArea.bottom + 16, 24))
    }
    
    // MARK: - Helpers
    
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

// MARK: - Progress Bar

private struct ProgressBar: View {
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
                // Background track
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.25))
                    .frame(height: 4)
                
                // Progress track
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: geometry.size.width * min(max(progress, 0), 1), height: 4)
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: isDragging ? 18 : 14, height: isDragging ? 18 : 14)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .offset(x: (geometry.size.width * min(max(progress, 0), 1)) - (isDragging ? 9 : 7))
                    .animation(.easeOut(duration: 0.1), value: isDragging)
            }
            .frame(height: 28)
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
        .frame(height: 28)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        Text("Video Player Preview")
            .foregroundColor(.white)
    }
}
