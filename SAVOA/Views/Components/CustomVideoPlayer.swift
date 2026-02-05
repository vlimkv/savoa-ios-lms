//
//  CustomVideoPlayer.swift
//  PelvicFloorApp
//
//  Created by 7Я on 04.12.2025.
//

import SwiftUI
import AVKit

struct CustomVideoPlayer: View {
    @ObservedObject var viewModel: VideoPlayerViewModel
    @State private var showControls = true
    @State private var hideControlsTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            if let player = viewModel.player {
                PlayerViewRepresentable(player: player)
                    .disabled(true)
                    .onTapGesture {
                        toggleControls()
                    }
            } else {
                Rectangle()
                    .fill(Color.black)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    )
            }
            
            if showControls {
                controlsOverlay
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
        .background(Color.black)
        .onAppear {
            scheduleHideControls()
        }
        .onChange(of: viewModel.isPlaying) { _, isPlaying in
            if isPlaying {
                scheduleHideControls()
            }
        }
    }
    
    private var controlsOverlay: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.7),
                    Color.clear,
                    Color.black.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Button {
                    viewModel.togglePlayPause()
                    scheduleHideControls()
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    progressBar
                    
                    HStack(spacing: 40) {
                        Button {
                            viewModel.seek(to: viewModel.currentTime - 10, isScrubbing: false)
                            scheduleHideControls()
                        } label: {
                            Image(systemName: "gobackward.10")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Button {
                            viewModel.seek(to: viewModel.currentTime + 10, isScrubbing: false)
                            scheduleHideControls()
                        } label: {
                            Image(systemName: "goforward.10")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: 200)
                }
                .padding()
                .background(Color.black.opacity(0.3))
            }
        }
    }
    
    private var progressBar: some View {
        HStack(spacing: 12) {
            Text(formatTime(viewModel.currentTime))
                .font(.caption)
                .foregroundColor(.white)
                .monospacedDigit()
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 3)
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(
                            width: geometry.size.width * (viewModel.currentTime / max(viewModel.duration, 1)),
                            height: 3
                        )
                    
                    Circle()
                        .fill(.white)
                        .frame(width: 12, height: 12)
                        .offset(x: (geometry.size.width * (viewModel.currentTime / max(viewModel.duration, 1))) - 6)
                }
                .cornerRadius(1.5)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            hideControlsTask?.cancel()
                            
                            let percent = min(max(value.location.x / geometry.size.width, 0), 1)
                            let newTime = percent * viewModel.duration
                            viewModel.seek(to: newTime, isScrubbing: true)
                        }
                        .onEnded { value in
                            let percent = min(max(value.location.x / geometry.size.width, 0), 1)
                            let newTime = percent * viewModel.duration
                            viewModel.seek(to: newTime, isScrubbing: false)
                            scheduleHideControls()
                        }
                )
            }
            .frame(height: 20)
            
            Text(formatTime(viewModel.duration))
                .font(.caption)
                .foregroundColor(.white)
                .monospacedDigit()
        }
    }
    
    private func toggleControls() {
        withAnimation {
            showControls.toggle()
        }
        if showControls {
            scheduleHideControls()
        }
    }
    
    private func scheduleHideControls() {
        hideControlsTask?.cancel()
        
        guard viewModel.isPlaying else { return }
        
        hideControlsTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                withAnimation {
                    showControls = false
                }
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else {
            return "0:00"
        }
        let totalSeconds = Int(seconds)
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

struct PlayerViewRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspect
        controller.view.backgroundColor = .black
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if uiViewController.player != player {
            uiViewController.player = player
        }
    }
}
