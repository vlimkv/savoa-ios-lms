//
//  RootView.swift
//  PelvicFloorApp
//
//  Created by 7Я on 04.12.2025.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView {
                    showSplash = false
                }
                .transition(.opacity)
            } else {
                Group {
                    if appState.isAuthenticated {
                        MainTabView()
                            .transition(.opacity)
                    } else {
                        LoginView()
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
}
