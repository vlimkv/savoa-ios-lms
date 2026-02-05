//
//  ProfileView.swift
//  PelvicFloorApp
//
//  Ultra Minimal Profile — seamless rows + premium flip (support/logout) — no modal, no “blocks”
//

import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject var appState: AppState

    @State private var completedLessons = 0
    @State private var totalMinutes = 0

    @AppStorage("notifications_enabled") private var notificationsEnabled = true

    // UI state
    @State private var cardMode: CardMode = .main

    enum CardMode { case main, support, logout }

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.top, 18)
                    .padding(.bottom, 22)

                statsRow
                    .padding(.bottom, 24)

                flipDeck
                    .padding(.horizontal, 20)

                Spacer(minLength: 0)
            }
            .onAppear {
                loadStats()
                Task { await syncNotifications() }
            }
            .onChange(of: notificationsEnabled) {
                Task { await syncNotifications() }
            }
            .animation(.spring(response: 0.75, dampingFraction: 0.92, blendDuration: 0.25), value: cardMode)
            .animation(.spring(response: 0.55, dampingFraction: 0.92, blendDuration: 0.2), value: notificationsEnabled)
        }
    }

    private func syncNotifications() async {
        if notificationsEnabled {
            let allowed = await NotificationService.shared.requestPermissionIfNeeded()
            if allowed {
                await NotificationService.shared.enableDailyWorkoutReminders()
            } else {
                notificationsEnabled = false
                await NotificationService.shared.disableDailyWorkoutReminders()
            }
        } else {
            await NotificationService.shared.disableDailyWorkoutReminders()
        }
    }
    
    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Text(userName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            if let user = appState.currentUser {
                Text(user.email)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 26) {
            StatItem(value: "\(completedLessons)", label: "уроков")
            StatItem(value: "\(totalMinutes)", label: "минут")
        }
    }

    // MARK: - Seamless Flip Deck (no card blocks / no rounded container)

    private var flipDeck: some View {
        ZStack {
            mainPanel
                .panelFX(active: cardMode == .main, direction: .left)

            supportPanel
                .panelFX(active: cardMode == .support, direction: .right)

            logoutPanel
                .panelFX(active: cardMode == .logout, direction: .right)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Panels

    private var mainPanel: some View {
        VStack(spacing: 0) {
            // Notifications (whole row toggles, toggle still works)
            Button {
                haptic(.light)
                notificationsEnabled.toggle()
            } label: {
                ActionRowContent(icon: "bell.fill", title: "Уведомления", isDestructive: false) {
                    Toggle("", isOn: $notificationsEnabled)
                        .labelsHidden()
                        .tint(.white)
                        .allowsHitTesting(true)
                }
            }
            .buttonStyle(RowButtonStyle())

            hairline

            Button {
                haptic(.light)
                flipTo(.support)
            } label: {
                ActionRowContent(icon: "headphones", title: "Поддержка", isDestructive: false) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.26))
                }
            }
            .buttonStyle(RowButtonStyle())

            hairline

            Button {
                haptic(.medium)
                flipTo(.logout)
            } label: {
                ActionRowContent(icon: "arrow.right.square", title: "Выйти", isDestructive: true) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red.opacity(0.42))
                }
            }
            .buttonStyle(RowButtonStyle())
        }
    }

    private var supportPanel: some View {
        VStack(spacing: 0) {
            Button {
                haptic(.light)
                flipTo(.main)
            } label: {
                ActionRowContent(icon: "chevron.left", title: "Назад", isDestructive: false) {
                    Text("Профиль")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.30))
                }
            }
            .buttonStyle(RowButtonStyle())

            hairline

            Button {
                haptic(.light)
                openURL("https://t.me/savoasupport")
            } label: {
                SupportRow(title: "Telegram", subtitle: "@savoasupport")
            }
            .buttonStyle(RowButtonStyle())

            hairline

            Button {
                haptic(.light)
                openURL("https://wa.me/77776776455")
            } label: {
                SupportRow(title: "WhatsApp", subtitle: "+7 777 677 6455")
            }
            .buttonStyle(RowButtonStyle())

            hairline

            Button {
                haptic(.light)
                openURL("mailto:info@savoa.kz")
            } label: {
                SupportRow(title: "Email", subtitle: "info@savoa.kz")
            }
            .buttonStyle(RowButtonStyle())
        }
    }

    private var logoutPanel: some View {
        VStack(spacing: 0) {
            Button {
                haptic(.light)
                flipTo(.main)
            } label: {
                ActionRowContent(icon: "chevron.left", title: "Назад", isDestructive: false) {
                    Text("Профиль")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.30))
                }
            }
            .buttonStyle(RowButtonStyle())

            hairline

            VStack(spacing: 10) {
                Text("Выйти из аккаунта?")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.top, 14)

                HStack(spacing: 10) {
                    Button {
                        haptic(.light)
                        flipTo(.main)
                    } label: {
                        Text("Отмена")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.86))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.05))
                    }
                    .buttonStyle(ScalePress())

                    Button {
                        haptic(.medium)
                        performLogout()
                    } label: {
                        Text("Выйти")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.92))
                    }
                    .buttonStyle(ScalePress())
                }
                .padding(.top, 2)
                .padding(.bottom, 14)
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Hairline separator (no “blocky” dividers)

    private var hairline: some View {
        Rectangle()
            .fill(Color.white.opacity(0.045))
            .frame(height: 1)
            .padding(.leading, 0)
            .padding(.trailing, 0)
            .padding(.vertical, 0)
    }

    // MARK: - Flip

    private func flipTo(_ mode: CardMode) {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.9, blendDuration: 0.22)) {
            cardMode = mode
        }
    }

    // MARK: - Data

    private var userName: String {
        guard let user = appState.currentUser else { return "Гость" }
        if !user.firstName.isEmpty {
            return user.firstName + (user.lastName.isEmpty ? "" : " \(user.lastName)")
        }
        return user.login ?? user.email.components(separatedBy: "@").first ?? "User"
    }

    private func loadStats() {
        let progress = ProgressService.shared
        completedLessons = progress.getTotalCompletedLessons()
        let allProgress = progress.getProgress()
        totalMinutes = Int(allProgress.lessonProgress.values.reduce(0) { $0 + $1.lastPosition }) / 60
    }

    private func performLogout() {
        AuthService.shared.logout()
        CourseService.shared.clearCache()
        ProgressService.shared.resetProgress()
        appState.logout()
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Panel FX (premium smooth: blur + fade + depth)

private enum FlipDirection { case left, right }

private extension View {
    func panelFX(active: Bool, direction: FlipDirection) -> some View {
        let sign: Double = (direction == .left) ? -1 : 1
        return self
            .opacity(active ? 1 : 0)
            .blur(radius: active ? 0 : 6)
            .scaleEffect(active ? 1 : 0.985, anchor: .center)
            .offset(y: active ? 0 : 6)
            .rotation3DEffect(
                .degrees(active ? 0 : (sign * 92)),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.86
            )
            .allowsHitTesting(active)
            .compositingGroup()
    }
}

// MARK: - Stat Item

private struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.4))
        }
    }
}

// MARK: - Row content

private struct ActionRowContent<Trailing: View>: View {
    let icon: String
    let title: String
    let isDestructive: Bool
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isDestructive ? .red.opacity(0.7) : .white.opacity(0.52))
                .frame(width: 24)

            Text(title)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(isDestructive ? .red.opacity(0.9) : .white.opacity(0.92))

            Spacer()

            trailing()
        }
        .padding(.horizontal, 2)       // less “card-like”
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

private struct SupportRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.up.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.30))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.92))
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.20))
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

// MARK: - Button styles

private struct RowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Rectangle()
                    .fill(Color.white.opacity(configuration.isPressed ? 0.055 : 0))
            )
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

private struct ScalePress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.988 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ProfileView().environmentObject(AppState())
    }
}
