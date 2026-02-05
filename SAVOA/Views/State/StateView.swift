//
//  StateView.swift
//  PelvicFloorApp
//
//  ✨ ULTRA PREMIUM STATE HUB ✨
//  Neon Design + Realistic Water + Full Integration
//

import SwiftUI

struct StateView: View {
    
    // MARK: - Storage
    
    @AppStorage("savoa_water_date") private var waterDateKey = ""
    @AppStorage("savoa_water_ml") private var waterML = 0
    @AppStorage("savoa_water_goal_ml") private var waterGoalML = 2000
    @AppStorage("savoa_water_step_ml") private var waterStepML = 250
    
    @AppStorage("savoa_habits_date") private var habitsDateKey = ""
    @AppStorage("savoa_habits_json") private var habitsJSON = ""
    
    // MARK: - State
    
    @State private var habits: [Habit] = []
    @State private var showWaterSettings = false
    @State private var showAddHabit = false
    
    // Navigation
    @State private var showStateTracker = false
    @State private var showGratitudeJournal = false
    
    // Neon glow animation
    @State private var glowIntensity: CGFloat = 0.5
    
    @State private var phaseStart = Date()
    
    private var todayKey: String { DateKey.today() }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background with subtle gradient
            backgroundGradient
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    topSection
                    quickActionsGrid
                    waterGlassCard
                    habitsCard
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
        .onAppear {
            bootstrapToday()
            loadData()
            startAnimations()
        }
        .sheet(isPresented: $showWaterSettings) {
            WaterSettingsSheet(goalML: $waterGoalML, stepML: $waterStepML)
        }
        .sheet(isPresented: $showAddHabit) {
            AddHabitSheet { habit in
                haptic(.soft)
                habits.append(habit)
                saveHabits()
            }
        }
        .fullScreenCover(isPresented: $showStateTracker) {
            NavigationStack {
                StateTrackerView()
            }
        }
        .fullScreenCover(isPresented: $showGratitudeJournal) {
            NavigationStack {
                GratitudeJournalView()
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Subtle neon ambient
            RadialGradient(
                colors: [
                    Color.cyan.opacity(0.03),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 100,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            RadialGradient(
                colors: [
                    Color.purple.opacity(0.02),
                    Color.clear
                ],
                center: .bottomLeading,
                startRadius: 50,
                endRadius: 350
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Top Section
    
    private var topSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Трекер")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(DateKey.prettyToday())
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                
                Spacer()
                
                // Week indicator dots with neon
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { i in
                        Circle()
                            .fill(i < 3 ? Color.cyan : Color.white.opacity(0.15))
                            .frame(width: 6, height: 6)
                            .shadow(color: i < 3 ? Color.cyan.opacity(0.6) : .clear, radius: 4)
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Actions Grid
    
    private var quickActionsGrid: some View {
        HStack(spacing: 12) {
            // State Tracker Card
            QuickActionCard(
                title: "Состояние",
                subtitle: "Настроение и симптомы",
                icon: "figure.mind.and.body",
                gradient: [Color(red: 0.4, green: 0.8, blue: 1.0), Color(red: 0.2, green: 0.5, blue: 0.9)],
                glowColor: .cyan,
                glowIntensity: glowIntensity
            ) {
                haptic(.medium)
                showStateTracker = true
            }
            
            // Gratitude Journal Card
            QuickActionCard(
                title: "Благодарность",
                subtitle: "Дневник записей",
                icon: "heart.text.square.fill",
                gradient: [Color(red: 1.0, green: 0.5, blue: 0.6), Color(red: 0.9, green: 0.3, blue: 0.5)],
                glowColor: .pink,
                glowIntensity: glowIntensity
            ) {
                haptic(.medium)
                showGratitudeJournal = true
            }
        }
    }
    
    // MARK: - Water Glass Card
    
    private var waterGlassCard: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 10) {
                    // Neon water drop icon
                    ZStack {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.cyan)
                            .blur(radius: 6)
                            .opacity(glowIntensity)
                        
                        Image(systemName: "drop.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.cyan)
                    }
                    
                    Text("Гидратация")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button {
                    haptic(.light)
                    showWaterSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.white.opacity(0.06)))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Glass and Stats
            HStack(spacing: 20) {
                TimelineView(.animation) { ctx in
                    let t = CGFloat(ctx.date.timeIntervalSince(phaseStart))
                    let phase = t * (.pi * 2) / 3.0

                    RealisticWaterGlass(
                        currentML: waterML,
                        goalML: waterGoalML,
                        wavePhase: phase,
                        glowIntensity: glowIntensity
                    )
                    .frame(width: 110, height: 180)
                }
                
                // Stats
                VStack(alignment: .leading, spacing: 16) {
                    // Main value
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(waterML)")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("мл")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        Text("из \(waterGoalML) мл")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    
                    // Progress indicator
                    let percent = min(100, Int((Double(waterML) / Double(max(waterGoalML, 1))) * 100))
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(percent >= 100 ? Color.green.opacity(0.2) : Color.cyan.opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: percent >= 100 ? "checkmark" : "drop.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(percent >= 100 ? .green : .cyan)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(percent)%")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(percent >= 100 ? .green : .white)
                            
                            Text(percent >= 100 ? "Цель достигнута!" : "выполнено")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
            
            // Controls
            HStack(spacing: 10) {
                // Minus
                Button {
                    haptic(.light)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        waterML = max(0, waterML - waterStepML)
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 56, height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                        )
                }
                
                // Add - main action with neon
                Button {
                    haptic(.medium)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        waterML = min(waterGoalML * 2, waterML + waterStepML)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                        Text("\(waterStepML) мл")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        ZStack {
                            // Glow
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.cyan)
                                .blur(radius: 12)
                                .opacity(glowIntensity * 0.5)
                            
                            // Button
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.cyan, Color(red: 0.3, green: 0.8, blue: 1.0)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    )
                }
                
                // Reset
                Button {
                    haptic(.rigid)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        waterML = 0
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 56, height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.white.opacity(0.04))
                        )
                }
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(Color.cyan.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Habits Card
    
    private var habitsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.purple)
                            .blur(radius: 5)
                            .opacity(glowIntensity)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.purple)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Привычки")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        if !habits.isEmpty {
                            let done = habits.filter { $0.isDoneToday }.count
                            Text("\(done) из \(habits.count)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    haptic(.soft)
                    showAddHabit = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.purple)
                            .blur(radius: 8)
                            .opacity(glowIntensity * 0.4)
                            .frame(width: 32, height: 32)
                        
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Habits list
            if habits.isEmpty {
                emptyHabitsView
            } else {
                VStack(spacing: 8) {
                    ForEach(habits) { habit in
                        HabitRow(
                            habit: habit,
                            onToggle: { toggleHabit(habit) },
                            onDelete: { deleteHabit(habit) }
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(Color.purple.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var emptyHabitsView: some View {
        HStack(spacing: 12) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.purple.opacity(0.6))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Добавь первую привычку")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("Начни с 2-3 простых действий")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    // MARK: - Logic
    
    private func bootstrapToday() {
        if waterDateKey != todayKey {
            waterDateKey = todayKey
            waterML = 0
        }
        if habitsDateKey != todayKey {
            habitsDateKey = todayKey
        }
    }
    
    private func loadData() {
        habits = Habit.decodeArray(habitsJSON) ?? defaultHabits()
        if habits.isEmpty {
            habits = defaultHabits()
            saveHabits()
        }
    }
    
    private func defaultHabits() -> [Habit] {
        [
            Habit(title: "Дыхание 2 минуты", icon: "wind"),
            Habit(title: "Движение 10 минут", icon: "figure.walk"),
            Habit(title: "Лечь до 23:00", icon: "moon.stars.fill")
        ]
    }
    
    private func saveHabits() {
        habitsJSON = Habit.encodeArray(habits) ?? ""
        habitsDateKey = todayKey
    }
    
    private func toggleHabit(_ habit: Habit) {
        guard let idx = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        haptic(.soft)
        habits[idx].doneDateKey = habits[idx].isDoneToday ? "" : todayKey
        saveHabits()
    }
    
    private func deleteHabit(_ habit: Habit) {
        haptic(.rigid)
        habits.removeAll { $0.id == habit.id }
        saveHabits()
    }
    
    private func startAnimations() {
        phaseStart = Date()

        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowIntensity = 0.8
        }
    }
    
    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Quick Action Card

private struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    let glowColor: Color
    let glowIntensity: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon with neon glow
                ZStack {
                    // Glow
                    Circle()
                        .fill(glowColor)
                        .blur(radius: 15)
                        .opacity(glowIntensity * 0.4)
                        .frame(width: 44, height: 44)
                    
                    // Icon background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
                
                Spacer(minLength: 0)
                
                // Arrow
                HStack {
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(glowColor.opacity(0.8))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(glowColor.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(CardPress())
    }
}

// MARK: - Realistic Water Glass

// ✅ DROP-IN “ULTRA PREMIUM” upgrade for RealisticWaterGlass
// Adds:
// 1) Micro-bubble dust near the bottom (stable + subtle shimmer)
// 2) Rare big bubbles (slow + occasional + fade at surface)
// 3) Caustics (light ripples) moving inside the water (masked + blend)
// No external libs. iOS 16+.

private struct RealisticWaterGlass: View {
    let currentML: Int
    let goalML: Int
    let wavePhase: CGFloat
    let glowIntensity: CGFloat
    
    private var fillPercent: CGFloat {
        min(1.0, CGFloat(currentML) / CGFloat(max(goalML, 1)))
    }
    
    // Deterministic random 0...1
    private func pseudoRand(_ i: Int, _ salt: Int) -> CGFloat {
        var x = UInt64(i * 1103515245 &+ salt * 12345)
        x ^= x >> 16
        x &*= 0x45d9f3b
        x ^= x >> 16
        return CGFloat(Double(x % 10_000) / 10_000.0)
    }
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let inset: CGFloat = 6
            
            let innerGlass = GlassShape().inset(by: 3)
            let bubbleClip = GlassShape().inset(by: inset)
            
            ZStack {
                // Glass shadow/glow
                GlassShape()
                    .fill(Color.cyan.opacity(0.1))
                    .blur(radius: 20)
                    .opacity(fillPercent > 0 ? glowIntensity * 0.5 : 0)
                
                // Glass body
                GlassShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.03),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // WATER CONTENT
                if currentML > 0 {
                    // Base water fill
                    WaterShape(progress: fillPercent, wavePhase: wavePhase)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.3, green: 0.85, blue: 1.0).opacity(0.85),
                                    Color(red: 0.2, green: 0.6, blue: 0.95).opacity(0.7),
                                    Color(red: 0.15, green: 0.45, blue: 0.85).opacity(0.8)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(innerGlass)
                    
                    // Caustics (subtle light ripples)
                    CausticsLayer(wavePhase: wavePhase, intensity: glowIntensity)
                        .clipShape(innerGlass)
                        .mask(
                            WaterShape(progress: fillPercent, wavePhase: wavePhase)
                                .fill(Color.white)
                                .clipShape(innerGlass)
                        )
                        .blendMode(.screen)
                        .opacity(0.55)
                        .allowsHitTesting(false)
                    
                    // Surface glow stroke
                    WaterShape(progress: fillPercent, wavePhase: wavePhase)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.7),
                                    Color.cyan.opacity(0.5)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 2
                        )
                        .clipShape(innerGlass)
                        .blur(radius: 1)
                    
                    // Bubble system (micro dust + normal + rare big)
                    BubbleSystem(
                        width: width,
                        height: height,
                        inset: inset,
                        fillPercent: fillPercent,
                        wavePhase: wavePhase,
                        rand: pseudoRand
                    )
                    .clipShape(bubbleClip)
                    .allowsHitTesting(false)
                }
                
                // Glass outline
                GlassShape()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                
                // Glass reflection
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 8, height: height * 0.5)
                    .offset(x: -width * 0.32, y: -height * 0.1)
            }
        }
    }
}

// MARK: - Bubble System (premium)

private struct BubbleSystem: View {
    let width: CGFloat
    let height: CGFloat
    let inset: CGFloat
    let fillPercent: CGFloat
    let wavePhase: CGFloat
    let rand: (Int, Int) -> CGFloat
    
    var body: some View {
        let surfaceY = height * (1 - fillPercent) + inset + 5
        let bottomY  = height - inset - 10
        let travel   = max(0, bottomY - surfaceY)
        
        ZStack {
            // 1) Micro-bubble dust near the bottom
            MicroDustLayer(
                width: width,
                height: height,
                inset: inset,
                surfaceY: surfaceY,
                bottomY: bottomY,
                wavePhase: wavePhase,
                rand: rand
            )
            
            // 2) Normal bubbles (more, subtle drift)
            ForEach(0..<12, id: \.self) { i in
                let r1 = rand(i, 11)
                let r2 = rand(i, 29)
                let r3 = rand(i, 47)
                let r4 = rand(i, 83)
                
                let size = 3 + r1 * 6
                let baseX = (r2 - 0.5) * width * 0.38
                let driftAmp = 3 + r3 * 6
                let driftSpeed = 0.9 + r4 * 1.4
                
                let phase = wavePhase * driftSpeed + CGFloat(i) * 1.37
                let t = (sin(phase) + 1) * 0.5
                let y = bottomY - travel * t
                
                let xDrift = sin(phase * 0.7 + CGFloat(i) * 0.9) * driftAmp
                
                // Fade out near surface
                let fadeStart: CGFloat = 0.82
                let fade = max(0, min(1, (fadeStart - t) / fadeStart))
                let alpha = (0.16 + r2 * 0.22) * fade
                let scale = 0.85 + 0.15 * fade
                
                Circle()
                    .fill(Color.white.opacity(alpha))
                    .frame(width: size * scale, height: size * scale)
                    .position(x: width * 0.5 + baseX + xDrift, y: y)
                    .blur(radius: 0.25)
            }
            
            // 3) Rare big bubbles (slow, occasional)
            ForEach(0..<3, id: \.self) { j in
                let i = 100 + j
                let r1 = rand(i, 17)
                let r2 = rand(i, 33)
                let r3 = rand(i, 71)
                
                let size = 10 + r1 * 10                 // 10...20
                let baseX = (r2 - 0.5) * width * 0.28   // safer to stay centered
                let speed = 0.18 + r3 * 0.22            // very slow
                
                // Occasional appearance via "gate"
                let gate = (sin(wavePhase * 0.35 + CGFloat(j) * 2.4) + 1) * 0.5 // 0..1
                let show = smoothstep(0.80, 0.95, gate)                         // appear rarely
                
                // Rising progress (slow)
                let t = (sin(wavePhase * speed + CGFloat(j) * 4.1) + 1) * 0.5
                let y = bottomY - travel * t
                
                // Fade near surface + also with show
                let fadeTop = max(0, min(1, (0.88 - t) / 0.88))
                let alpha = (0.16 * fadeTop + 0.08) * show
                
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(alpha), lineWidth: 1.2)
                        .frame(width: size, height: size)
                        .blur(radius: 0.2)

                    Circle()
                        .fill(Color.white.opacity(alpha * 0.25))
                        .frame(width: size * 0.85, height: size * 0.85)
                        .blur(radius: 0.4)
                }
                .opacity(show)
                .position(x: width * 0.5 + baseX, y: y)
            }
        }
        .frame(width: width, height: height)
    }
    
    private func smoothstep(_ a: CGFloat, _ b: CGFloat, _ x: CGFloat) -> CGFloat {
        let t = max(0, min(1, (x - a) / (b - a)))
        return t * t * (3 - 2 * t)
    }
}

// MARK: - Micro bubble dust (bottom shimmer)

private struct MicroDustLayer: View {
    let width: CGFloat
    let height: CGFloat
    let inset: CGFloat
    let surfaceY: CGFloat
    let bottomY: CGFloat
    let wavePhase: CGFloat
    let rand: (Int, Int) -> CGFloat
    
    var body: some View {
        let dustTop = max(surfaceY + 18, bottomY - 42) // only near bottom
        let dustHeight = max(8, bottomY - dustTop)
        
        ZStack {
            ForEach(0..<34, id: \.self) { i in
                let r1 = rand(i, 101)
                let r2 = rand(i, 203)
                let r3 = rand(i, 307)
                
                let size = 1.2 + r1 * 1.8                 // tiny
                let x = inset + (width - inset * 2) * r2
                let y = dustTop + dustHeight * r3
                
                // subtle shimmer
                let tw = (sin(wavePhase * 1.2 + CGFloat(i) * 0.9) + 1) * 0.5
                let alpha = 0.06 + tw * 0.10
                
                Circle()
                    .fill(Color.white.opacity(alpha))
                    .frame(width: size, height: size)
                    .position(x: x, y: y)
                    .blur(radius: 0.15)
            }
        }
        .blendMode(.screen)
        .opacity(0.85)
        .allowsHitTesting(false)
    }
}

// MARK: - Caustics Layer (light ripples)

private struct CausticsLayer: View {
    let wavePhase: CGFloat
    let intensity: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                // Layer 1
                CausticsPattern(phase: wavePhase * 0.55, scale: 1.0)
                    .frame(width: w * 1.3, height: h * 1.1)
                    .offset(x: sin(wavePhase * 0.25) * 10, y: cos(wavePhase * 0.22) * 8)
                    .opacity(0.22 + intensity * 0.08)
                
                // Layer 2 (different motion)
                CausticsPattern(phase: wavePhase * 0.75 + 1.7, scale: 0.85)
                    .frame(width: w * 1.2, height: h * 1.0)
                    .offset(x: cos(wavePhase * 0.21) * 12, y: sin(wavePhase * 0.18) * 10)
                    .opacity(0.18 + intensity * 0.06)
            }
            .blur(radius: 0.4)
        }
        .allowsHitTesting(false)
    }
}

private struct CausticsPattern: View {
    let phase: CGFloat
    let scale: CGFloat
    
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let lineW: CGFloat = 1.0 * scale
            
            let twoPi: CGFloat = .pi * 2
            let a1: CGFloat = 1.8 * scale
            let a2: CGFloat = 2.7 * scale
            let amp1: CGFloat = 6 * scale
            let amp2: CGFloat = 4 * scale
            
            for k in 0..<12 {
                let t = CGFloat(k) / 12
                let yBase = h * t
                
                var path = Path()
                let steps = 50
                
                for i in 0...steps {
                    let fx = CGFloat(i) / CGFloat(steps)
                    let x = w * fx
                    
                    let p1 = fx * twoPi * a1 + phase + t * 6.2
                    let p2 = fx * twoPi * a2 - phase * 0.9 + t * 3.7
                    
                    let y = yBase + sin(p1) * amp1 + cos(p2) * amp2
                    
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
                
                context.stroke(
                    path,
                    with: .color(Color.white.opacity(0.35)),
                    lineWidth: lineW
                )
            }
        }
        .allowsHitTesting(false)
    }
}


// MARK: - Glass Shape

private struct GlassShape: Shape, InsettableShape {
    var insetAmount: CGFloat = 0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let topWidth = rect.width - insetAmount * 2
        let bottomWidth = topWidth * 0.7
        _ = rect.height - insetAmount * 2
        let cornerRadius: CGFloat = 6
        
        let topLeft = CGPoint(x: rect.midX - topWidth / 2, y: rect.minY + insetAmount)
        let topRight = CGPoint(x: rect.midX + topWidth / 2, y: rect.minY + insetAmount)
        let bottomRight = CGPoint(x: rect.midX + bottomWidth / 2, y: rect.maxY - insetAmount)
        let bottomLeft = CGPoint(x: rect.midX - bottomWidth / 2, y: rect.maxY - insetAmount)
        
        path.move(to: CGPoint(x: topLeft.x + cornerRadius, y: topLeft.y))
        path.addLine(to: CGPoint(x: topRight.x - cornerRadius, y: topRight.y))
        path.addQuadCurve(to: CGPoint(x: topRight.x, y: topRight.y + cornerRadius), control: topRight)
        path.addLine(to: CGPoint(x: bottomRight.x, y: bottomRight.y - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: bottomRight.x - cornerRadius, y: bottomRight.y), control: bottomRight)
        path.addLine(to: CGPoint(x: bottomLeft.x + cornerRadius, y: bottomLeft.y))
        path.addQuadCurve(to: CGPoint(x: bottomLeft.x, y: bottomLeft.y - cornerRadius), control: bottomLeft)
        path.addLine(to: CGPoint(x: topLeft.x, y: topLeft.y + cornerRadius))
        path.addQuadCurve(to: CGPoint(x: topLeft.x + cornerRadius, y: topLeft.y), control: topLeft)
        path.closeSubpath()
        
        return path
    }
    
    func inset(by amount: CGFloat) -> GlassShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}

// MARK: - Water Shape with Wave

private struct WaterShape: Shape {
    var progress: CGFloat
    var wavePhase: CGFloat
    
    var animatableData: CGFloat {
        get { wavePhase }
        set { wavePhase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let topWidth = rect.width
        let bottomWidth = topWidth * 0.7
        let waterTop = rect.height * (1 - progress)
        let waveHeight: CGFloat = 6
        
        // Bottom corners
        let bottomLeft = CGPoint(x: rect.midX - bottomWidth / 2 + 4, y: rect.maxY - 4)
        let bottomRight = CGPoint(x: rect.midX + bottomWidth / 2 - 4, y: rect.maxY - 4)
        
        // Water edge positions (accounting for glass taper)
        let taperFactor = 1 - (1 - progress) * 0.3
        let waterWidth = topWidth * taperFactor - 8
        let leftX = rect.midX - waterWidth / 2
        let rightX = rect.midX + waterWidth / 2
        
        path.move(to: bottomLeft)
        path.addLine(to: bottomRight)
        path.addLine(to: CGPoint(x: rightX, y: waterTop))
        
        // Wave across top
        let steps = 40
        for i in stride(from: steps, through: 0, by: -1) {
            let x = rightX - (rightX - leftX) * CGFloat(steps - i) / CGFloat(steps)
            let waveX = CGFloat(i) / CGFloat(steps) * .pi * 4
            let y = waterTop + sin(waveX + wavePhase) * waveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: bottomLeft)
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Habit Row

private struct HabitRow: View {
    let habit: Habit
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(habit.isDoneToday ? Color.green.opacity(0.15) : Color.white.opacity(0.05))
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(habit.isDoneToday ? Color.green.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                        )
                    
                    if habit.isDoneToday {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: habit.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .shadow(color: habit.isDoneToday ? Color.green.opacity(0.3) : .clear, radius: 8)
            }
            
            Text(habit.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(habit.isDoneToday ? 0.9 : 0.7))
                .lineLimit(1)
            
            Spacer()
            
            Menu {
                Button(role: .destructive, action: onDelete) {
                    Label("Удалить", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(habit.isDoneToday ? Color.white.opacity(0.03) : Color.white.opacity(0.02))
        )
    }
}

// MARK: - Card Press Style

private struct CardPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Sheets

private struct WaterSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var goalML: Int
    @Binding var stepML: Int
    
    @State private var goalText = ""
    @State private var stepText = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Дневная цель (мл)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                        
                        TextField("2000", text: $goalText)
                            .keyboardType(.numberPad)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(Color.white.opacity(0.05))
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Шаг добавления (мл)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                        
                        TextField("250", text: $stepText)
                            .keyboardType(.numberPad)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(Color.white.opacity(0.05))
                            )
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Настройки воды")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        if let g = Int(goalText), g >= 500, g <= 5000 { goalML = g }
                        if let s = Int(stepText), s >= 50, s <= 1000 { stepML = s }
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
            .onAppear {
                goalText = "\(goalML)"
                stepText = "\(stepML)"
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct AddHabitSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onAdd: (Habit) -> Void
    
    @State private var title = ""
    @State private var icon = "sparkles"
    
    private let icons = ["sparkles", "wind", "figure.walk", "moon.stars.fill", "leaf.fill", "drop.fill", "sun.max.fill", "figure.strengthtraining.traditional", "book.fill", "heart.fill"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Название")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                        
                        TextField("Дыхание 2 минуты", text: $title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(Color.white.opacity(0.05))
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Иконка")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 10) {
                            ForEach(icons, id: \.self) { ic in
                                Button { icon = ic } label: {
                                    Image(systemName: ic)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(icon == ic ? .purple : .white.opacity(0.5))
                                        .frame(width: 50, height: 50)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                                .fill(Color.white.opacity(icon == ic ? 0.15 : 0.05))
                                        )
                                        .shadow(color: icon == ic ? Color.purple.opacity(0.4) : .clear, radius: 8)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Новая привычка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Добавить") {
                        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard t.count >= 2 else { return }
                        onAdd(Habit(title: t, icon: icon))
                        dismiss()
                    }
                    .foregroundColor(.purple)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).count < 2)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Models

private struct Habit: Identifiable, Codable {
    let id: UUID
    var title: String
    var icon: String
    var doneDateKey: String
    
    init(id: UUID = UUID(), title: String, icon: String, doneDateKey: String = "") {
        self.id = id
        self.title = title
        self.icon = icon
        self.doneDateKey = doneDateKey
    }
    
    var isDoneToday: Bool { doneDateKey == DateKey.today() }
    
    static func encodeArray(_ value: [Habit]) -> String? {
        try? String(data: JSONEncoder().encode(value), encoding: .utf8)
    }
    
    static func decodeArray(_ string: String) -> [Habit]? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([Habit].self, from: data)
    }
}

private enum DateKey {
    static func today() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
    
    static func prettyToday() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "d MMMM"
        return f.string(from: Date())
    }
}

#Preview {
    StateView()
        .preferredColorScheme(.dark)
}
