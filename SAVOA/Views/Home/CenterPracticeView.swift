//
//  CenterPracticeView.swift
//  PelvicFloorApp
//
//  Дыхательная практика — Море на весь экран
//

import SwiftUI

struct CenterPracticeView: View {
    private enum Phase {
        case ready
        case inhale
        case hold
        case exhale
        case rest
    }
    
    // MARK: - State
    
    @Environment(\.dismiss) private var dismiss
    @State private var phase: Phase = .ready
    @State private var phaseProgress: CGFloat = 0.0
    @State private var isRunning: Bool = false
    @State private var cycleCount: Int = 0
    @State private var phaseRemainingSeconds: Int = 0
    @State private var showExitConfirm: Bool = false
    
    private let targetCycles: Int = 5
    
    private let inhaleDuration: Double = 4
    private let holdDuration: Double = 2
    private let exhaleDuration: Double = 6
    private let restDuration: Double = 2
    
    @State private var timer: Timer? = nil
    @State private var phaseStartDate: Date = Date()
    @State private var phaseDuration: Double = 0
    
    private let soundManager = BreathSoundManager.shared
    
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize
    private var isIPad: Bool { hSize == .regular && vSize == .regular }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Базовый черный фон
                Color.black.ignoresSafeArea()
                
                // МОРЕ НА ВЕСЬ ЭКРАН
                OceanWaveView(
                    color: phaseMainColor,
                    progress: waveProgress,
                    screenHeight: geometry.size.height,
                    screenWidth: geometry.size.width
                )
                .ignoresSafeArea()
                
                // Контент поверх моря
                VStack(spacing: 0) {
                    // Кнопка закрытия
                    HStack {
                        Button {
                            handleExit()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .padding(.leading, 20)
                        .padding(.top, 16)
                        
                        Spacer()
                    }
                    
                    Spacer()
                        .frame(height: 40)
                    
                    // Фаза и время
                    VStack(spacing: 10) {
                        Text(phaseShortTitle.uppercased())
                            .font(.system(size: isIPad ? 16 : 14, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(3)
                        
                        if let seconds = isRunning ? phaseRemainingSeconds : nil {
                            Text("\(max(seconds, 0))")
                                .font(.system(size: isIPad ? 90 : 72, weight: .bold))
                                .foregroundColor(.white)
                                .monospacedDigit()
                        } else {
                            Text("—")
                                .font(.system(size: isIPad ? 90 : 72, weight: .bold))
                                .foregroundColor(.white.opacity(0.35))
                        }
                        
                        Text(promptTitle)
                            .font(.system(size: isIPad ? 15 : 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, isIPad ? 50 : 32)
                            .lineSpacing(3)
                    }
                    .animation(.easeInOut(duration: 0.25), value: phase)
                    
                    Spacer()
                    
                    // Инфо снизу
                    VStack(spacing: 8) {
                        if !isRunning && cycleCount == 0 {
                            Text("Дыхание к тазовому дну")
                                .font(.system(size: isIPad ? 12 : 11, weight: .regular))
                                .foregroundColor(.white.opacity(0.5))
                        } else if cycleCount > 0 && !isRunning {
                            VStack(spacing: 4) {
                                Text("Практика завершена")
                                    .font(.system(size: isIPad ? 13 : 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.85))
                                
                                Text("\(cycleCount) из \(targetCycles) циклов")
                                    .font(.system(size: isIPad ? 11 : 10, weight: .regular))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        
                        // Кнопка
                        controlButton
                            .padding(.horizontal, isIPad ? 40 : 20)
                            .padding(.top, 8)
                    }
                    .padding(.bottom, isIPad ? 50 : 40)
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .alert("Завершить практику?", isPresented: $showExitConfirm) {
            Button("Продолжить", role: .cancel) { }
            Button("Завершить", role: .destructive) {
                stopPractice()
                dismiss()
            }
        } message: {
            Text("Вы прошли \(cycleCount) из \(targetCycles) циклов")
        }
        .onDisappear {
            stopPractice()
        }
    }
    
    // MARK: - Exit Handler
    
    private func handleExit() {
        if isRunning {
            showExitConfirm = true
        } else {
            dismiss()
        }
    }
    
    // MARK: - Wave Progress
    
    private var waveProgress: CGFloat {
        switch phase {
        case .ready:
            return 0.0
        case .inhale:
            return phaseProgress
        case .hold:
            return 1.0
        case .exhale:
            return 1.0 - phaseProgress
        case .rest:
            return 0.12
        }
    }
    
    // MARK: - Colors & Text
    
    private var phaseMainColor: Color {
        switch phase {
        case .ready:
            return Color(red: 0.15, green: 0.2, blue: 0.3)
        case .inhale:
            return Color(red: 0.3, green: 0.5, blue: 0.75)
        case .hold:
            return Color(red: 0.4, green: 0.35, blue: 0.65)
        case .exhale:
            return Color(red: 0.75, green: 0.4, blue: 0.55)
        case .rest:
            return Color(red: 0.25, green: 0.3, blue: 0.4)
        }
    }
    
    private var phaseShortTitle: String {
        switch phase {
        case .ready: return "Готовы"
        case .inhale: return "Вдох"
        case .hold: return "Пауза"
        case .exhale: return "Выдох"
        case .rest: return "Отдых"
        }
    }
    
    private var promptTitle: String {
        switch phase {
        case .ready: return "Найдите устойчивость"
        case .inhale: return "Вдох вниз к тазовому дну"
        case .hold: return "Мягкая пауза"
        case .exhale: return "Выдох собирает вверх"
        case .rest: return "Короткий отдых"
        }
    }
    
    // MARK: - Button
    
    private var controlButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                if isRunning {
                    stopPractice()
                } else {
                    startPractice()
                }
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: isIPad ? 13 : 12, weight: .bold))
                
                Text(isRunning ? "Пауза" : (cycleCount > 0 ? "Продолжить" : "Начать"))
                    .font(.system(size: isIPad ? 14 : 13, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: isIPad ? 52 : 48)
            .background(
                RoundedRectangle(cornerRadius: isIPad ? 14 : 12, style: .continuous)
                    .fill(Color.white)
            )
            .foregroundColor(.black)
        }
    }
    
    // MARK: - Logic
    
    private func startPractice() {
        if cycleCount == 0 {
            stopPractice()
        }
        isRunning = true
        switchToPhase(.inhale, duration: inhaleDuration)
        startTimer()
    }
    
    private func stopPractice() {
        isRunning = false
        phase = .ready
        phaseProgress = 0
        phaseRemainingSeconds = 0
        timer?.invalidate()
        timer = nil
        soundManager.stopAll()
    }
    
    private func startTimer() {
        phaseStartDate = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            updatePhaseProgress()
        }
    }
    
    private func switchToPhase(_ newPhase: Phase, duration: Double) {
        withAnimation(.easeInOut(duration: 0.2)) {
            phase = newPhase
        }
        phaseDuration = duration
        phaseStartDate = Date()
        phaseProgress = 0
        phaseRemainingSeconds = Int(duration.rounded(.up))
        handleSound(for: newPhase)
    }
    
    private func handleSound(for phase: Phase) {
        switch phase {
        case .inhale:
            soundManager.stopHeartbeat()
            soundManager.playInhale()
        case .hold:
            soundManager.startHeartbeat()
        case .exhale:
            soundManager.stopHeartbeat()
            soundManager.playExhale()
        case .rest:
            soundManager.stopHeartbeat()
        case .ready:
            soundManager.stopAll()
        }
    }
    
    private func updatePhaseProgress() {
        guard isRunning else { return }
        
        let elapsed = Date().timeIntervalSince(phaseStartDate)
        let duration = max(phaseDuration, 0.01)
        let progress = min(max(elapsed / duration, 0), 1)
        phaseProgress = CGFloat(progress)
        
        let remaining = max(duration - elapsed, 0)
        phaseRemainingSeconds = Int(ceil(remaining))
        
        if elapsed >= phaseDuration {
            advancePhase()
        }
    }
    
    private func advancePhase() {
        switch phase {
        case .inhale:
            switchToPhase(.hold, duration: holdDuration)
        case .hold:
            switchToPhase(.exhale, duration: exhaleDuration)
        case .exhale:
            switchToPhase(.rest, duration: restDuration)
        case .rest:
            cycleCount += 1
            if cycleCount >= targetCycles {
                stopPractice()
            } else {
                switchToPhase(.inhale, duration: inhaleDuration)
            }
        case .ready:
            break
        }
    }
}

// MARK: - OceanWaveView — Море как в реальности

private struct OceanWaveView: View {
    let color: Color
    let progress: CGFloat
    let screenHeight: CGFloat
    let screenWidth: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Основная масса воды
                OceanFillShape(progress: progress, screenHeight: geo.size.height)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.95),
                                color.opacity(0.8),
                                color.opacity(0.6),
                                color.opacity(0.35)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .animation(.easeInOut(duration: 0.7), value: progress)
                
                // Первая волна (главная)
                OceanWaveShape(
                    progress: progress,
                    screenHeight: geo.size.height,
                    waveOffset: 0,
                    amplitude: 35,
                    frequency: 2.0
                )
                .fill(color.opacity(0.5))
                .animation(.easeInOut(duration: 0.7), value: progress)
                .blendMode(.screen)
                
                // Вторая волна (средняя)
                OceanWaveShape(
                    progress: progress,
                    screenHeight: geo.size.height,
                    waveOffset: 0.4,
                    amplitude: 25,
                    frequency: 2.5
                )
                .fill(color.opacity(0.3))
                .animation(.easeInOut(duration: 0.7), value: progress)
                .blendMode(.screen)
                
                // Третья волна (дальняя)
                OceanWaveShape(
                    progress: progress,
                    screenHeight: geo.size.height,
                    waveOffset: 0.7,
                    amplitude: 18,
                    frequency: 3.0
                )
                .fill(color.opacity(0.15))
                .animation(.easeInOut(duration: 0.7), value: progress)
                .blendMode(.screen)
            }
        }
    }
}

// MARK: - OceanFillShape — Заливка океана

private struct OceanFillShape: Shape {
    var progress: CGFloat
    let screenHeight: CGFloat
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let waveY = calculateWaveY()
        
        // От низа экрана
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        
        // До линии волны
        path.addLine(to: CGPoint(x: rect.width, y: waveY))
        path.addLine(to: CGPoint(x: 0, y: waveY))
        
        path.closeSubpath()
        
        return path
    }
    
    private func calculateWaveY() -> CGFloat {
        let minY = screenHeight * 0.88  // внизу
        let maxY = screenHeight * 0.08  // вверху
        return minY - (minY - maxY) * progress
    }
}

// MARK: - OceanWaveShape — Волны океана

private struct OceanWaveShape: Shape {
    var progress: CGFloat
    let screenHeight: CGFloat
    var waveOffset: CGFloat
    var amplitude: CGFloat
    var frequency: CGFloat
    
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(progress, waveOffset) }
        set {
            progress = newValue.first
            waveOffset = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let waveY = calculateWaveY()
        let width = rect.width
        let height = rect.height
        
        // Волнистая линия сверху
        path.move(to: CGPoint(x: 0, y: waveY))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin((relativeX * frequency * .pi * 2) + (progress * .pi * 2) + (waveOffset * .pi * 2))
            let y = waveY + sine * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // Заливка вниз
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
    
    private func calculateWaveY() -> CGFloat {
        let minY = screenHeight * 0.88
        let maxY = screenHeight * 0.08
        return minY - (minY - maxY) * progress
    }
}

#Preview {
    NavigationStack {
        CenterPracticeView()
    }
}
