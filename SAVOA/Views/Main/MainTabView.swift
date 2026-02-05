//
//  MainTabView.swift
//  PelvicFloorApp
//
//  Clean 3-tab navigation — Profile opens from Home avatar
//

import SwiftUI
import UIKit

struct MainTabView: View {
    @State private var selectedTab: Tab = .home

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black

        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(white: 0.4, alpha: 1.0)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(white: 0.4, alpha: 1.0)
        ]

        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Главная", systemImage: "house.fill") }
            .tag(Tab.home)

            // Program Tab
            NavigationStack {
                ProgramView()
            }
            .tabItem { Label("Программа", systemImage: "list.bullet.rectangle") }
            .tag(Tab.program)

            // State Tab
            NavigationStack {
                StateView()
            }
            .tabItem { Label("Состояние", systemImage: "waveform.path.ecg") }
            .tag(Tab.state)
        }
    }
}

enum Tab: Hashable {
    case home
    case program
    case state
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
        .environmentObject(FullscreenManager.shared)
}
