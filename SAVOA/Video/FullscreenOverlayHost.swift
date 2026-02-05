//
//  FullscreenOverlayHost.swift
//  PelvicFloorApp
//
//  Wraps content and shows fullscreen video overlay when needed
//

import SwiftUI

struct FullscreenOverlayHost<Content: View>: View {
    @StateObject private var manager = FullscreenManager.shared
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            content
                .environmentObject(manager)
            
            if manager.isFullscreen, let viewModel = manager.videoPlayerViewModel {
                FullscreenVideoOverlay(viewModel: viewModel) {
                    manager.exitFullscreen()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(9999)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: manager.isFullscreen)
    }
}
