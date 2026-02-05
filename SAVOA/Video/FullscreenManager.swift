//
//  FullscreenManager.swift
//  PelvicFloorApp
//
//  Manages fullscreen video state
//

import SwiftUI
import Combine

@MainActor
final class FullscreenManager: ObservableObject {
    static let shared = FullscreenManager()
    
    @Published private(set) var isFullscreen = false
    @Published private(set) var videoPlayerViewModel: VideoPlayerViewModel?
    
    private init() {}
    
    func enterFullscreen(with viewModel: VideoPlayerViewModel) {
        videoPlayerViewModel = viewModel
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isFullscreen = true
        }
    }
    
    func exitFullscreen() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isFullscreen = false
        }
        
        // Clear reference after animation
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            self.videoPlayerViewModel = nil
        }
    }
}
