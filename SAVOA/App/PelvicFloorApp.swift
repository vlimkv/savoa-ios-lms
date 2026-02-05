//
//  PelvicFloorApp.swift
//  PelvicFloorApp
//

import SwiftUI

@main
struct PelvicFloorApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var fullscreenManager = FullscreenManager.shared

    @State private var resetPasswordToken: ResetTokenItem? = nil

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main content
                RootView()
                    .environmentObject(appState)
                    .environmentObject(fullscreenManager)
                    .opacity(fullscreenManager.isFullscreen ? 0 : 1)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: fullscreenManager.isFullscreen)
            .onOpenURL { url in
                // pelvic://reset-password?token=XXXX
                guard url.scheme == "pelvic" else { return }

                let host = (url.host ?? "").lowercased()
                let path = url.path.lowercased()

                let isReset = (host == "reset-password") || (path == "/reset-password")
                guard isReset else { return }

                let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
                let token = comps?.queryItems?.first(where: { $0.name == "token" })?.value

                guard let token, !token.isEmpty else { return }

                resetPasswordToken = ResetTokenItem(token: token)
            }
            .sheet(item: $resetPasswordToken) { item in
                ResetPasswordView(token: item.token)
            }
        }
    }
}

private struct ResetTokenItem: Identifiable {
    let id = UUID()
    let token: String
}
