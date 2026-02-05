//
//  MeditationPlayerView.swift
//  PelvicFloorApp
//
//  Premium Meditation Player — ULTRA РЕАЛИСТИЧНО
//

import SwiftUI
import AVFoundation

// MARK: - Ambient Sound Model

enum AmbientSound: String, CaseIterable, Identifiable {
    case none = "Без звука"
    case birds = "Птицы"
    case ocean = "Океан"
    case rain = "Дождь"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .none: return "speaker.slash.fill"
        case .birds: return "bird.fill"
        case .ocean: return "water.waves"
        case .rain: return "cloud.rain.fill"
        }
    }
    
    var fileName: String {
        switch self {
        case .none: return ""
        case .birds: return "ambient_birds.mp3"
        case .ocean: return "ambient_ocean.mp3"
        case .rain: return "ambient_rain.mp3"
        }
    }
}

struct MeditationPlayerView: View {
    let item: MeditationItem
    @ObservedObject var audioPlayer: AudioMeditationPlayer
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentTime: Double = 0
    @State private var duration: Double = 360
    @State private var isDragging: Bool = false
    @State private var timer: Timer?
    @State private var orbPhase: CGFloat = 0
    @State private var showDescription: Bool = true
    @State private var showAmbientPicker: Bool = false
    @State private var selectedAmbient: AmbientSound = .none
    @State private var ambientPlayer: AVAudioPlayer?
    @State private var ambientVolume: Float = 0.05
    @State private var particles: [AmbientParticle] = []
    @State private var particleTimer: Timer?
    @State private var birdWingTimer: Timer?
    
    private var isActive: Bool { audioPlayer.nowPlayingID == item.id }
    private var isPlaying: Bool { isActive && audioPlayer.isPlaying }
    
    private func syncTimeline() {
        if isActive, let player = audioPlayer.player {
            duration = max(player.duration, 0.1)
            currentTime = player.currentTime
        } else {
            currentTime = 0
            duration = max(loadDurationForCurrentItem(), 0.1)
        }
    }
    
    private func loadDurationForCurrentItem() -> Double {
        guard let url = audioPlayerDurationURL(for: item.audioFileName) else { return 360 }
        do {
            let temp = try AVAudioPlayer(contentsOf: url)
            return temp.duration
        } catch {
            return 360
        }
    }

    private func audioPlayerDurationURL(for file: String) -> URL? {
        if file.contains("/") {
            let parts = file.split(separator: "/").map(String.init)
            let last = parts.last ?? file
            let subdir = parts.dropLast().joined(separator: "/")
            let (name, ext) = splitNameExt_forDuration(fileName: last)
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdir) { return url }
        }

        let (name, ext) = splitNameExt_forDuration(fileName: file)
        if let url = Bundle.main.url(forResource: name, withExtension: ext) { return url }
        if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resources") { return url }
        return nil
    }

    private func splitNameExt_forDuration(fileName: String) -> (String, String?) {
        let comps = fileName.split(separator: ".", omittingEmptySubsequences: false)
        guard comps.count >= 2 else { return (fileName, nil) }
        let name = comps.dropLast().joined(separator: ".")
        let ext = String(comps.last ?? "")
        return (String(name), ext.isEmpty ? nil : ext)
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            if selectedAmbient != .none && isPlaying {
                ambientParticlesView
            }
            
            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                
                Spacer()
                
                if showDescription {
                    descriptionCard
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    contentArea
                        .padding(.horizontal, 24)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
                
                controlsArea
                    .padding(.horizontal, 24)
                    .padding(.bottom, 44)
            }
            
            if showAmbientPicker {
                ambientSoundPicker
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupAudio()
            syncTimeline()
            startOrbAnimation()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
            birdWingTimer?.invalidate()
            birdWingTimer = nil
            particleTimer?.invalidate()
            stopAmbientSound()
            particles.removeAll()
            if audioPlayer.nowPlayingID == item.id {
                audioPlayer.stop()
            }
        }
        .onChange(of: audioPlayer.nowPlayingID) {
            syncTimeline()
            setupAudio()
        }
        .onChange(of: audioPlayer.isPlaying) {
            syncTimeline()
            setupAudio()
        }
        .onChange(of: item.id) {
            currentTime = 0
            duration = max(loadDurationForCurrentItem(), 0.1)
            syncTimeline()
            setupAudio()
        }
    }
    
    private var backgroundGradient: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.04, green: 0.03, blue: 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            RadialGradient(
                colors: [
                    orbColor.opacity(0.3),
                    orbColor.opacity(0.15),
                    Color.clear
                ],
                center: UnitPoint(x: 0.3, y: 0.4),
                startRadius: 50,
                endRadius: 350
            )
            .blur(radius: 60)
            
            RadialGradient(
                colors: [
                    secondaryOrbColor.opacity(0.25),
                    Color.clear
                ],
                center: UnitPoint(x: 0.7, y: 0.6),
                startRadius: 40,
                endRadius: 300
            )
            .blur(radius: 50)
        }
        .ignoresSafeArea()
    }
    
    private var ambientParticlesView: some View {
        ZStack {
            ForEach(particles) { particle in
                particleView(for: particle)
            }
        }
        .ignoresSafeArea()
    }
    
    private func particleView(for particle: AmbientParticle) -> some View {
        Group {
            switch selectedAmbient {
            case .birds:
                // Птица: корпус + крылья
                ZStack {
                    // Тело птицы
                    Capsule()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 12, height: 8)
                    
                    // Левое крыло
                    Ellipse()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 8, height: 4)
                        .offset(x: -8, y: 0)
                        .rotationEffect(.degrees(-20 + particle.wingFlap))
                    
                    // Правое крыло
                    Ellipse()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 8, height: 4)
                        .offset(x: 8, y: 0)
                        .rotationEffect(.degrees(20 - particle.wingFlap))
                }
                .rotationEffect(.degrees(particle.rotation))
                
            case .ocean:
                // Волна: несколько кругов
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 30, height: 30)
                    Circle()
                        .stroke(Color.blue.opacity(0.25), lineWidth: 1)
                        .frame(width: 35, height: 35)
                    Circle()
                        .stroke(Color.blue.opacity(0.15), lineWidth: 0.5)
                        .frame(width: 40, height: 40)
                }
                .scaleEffect(particle.scale)
                
            case .rain:
                // Капля дождя: вертикальная линия с каплей
                ZStack {
                    // Линия падения
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.4),
                                    Color.blue.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 1, height: 20)
                    
                    // Капля
                    Circle()
                        .fill(Color.blue.opacity(0.5))
                        .frame(width: 4, height: 4)
                        .offset(y: -10)
                }
                .rotationEffect(.degrees(particle.rotation * 0.2))
                
            case .none:
                EmptyView()
            }
        }
        .opacity(particle.opacity)
        .offset(x: particle.x, y: particle.y)
    }
    
    private var orbColor: Color {
        switch item.category {
        case "Сон": return Color(red: 0.4, green: 0.5, blue: 0.9)
        case "Любовь": return Color(red: 0.9, green: 0.4, blue: 0.6)
        case "Старт": return Color(red: 0.9, green: 0.65, blue: 0.25)
        default: return Color(red: 0.5, green: 0.6, blue: 0.9)
        }
    }

    private var secondaryOrbColor: Color {
        switch item.category {
        case "Сон": return Color(red: 0.6, green: 0.3, blue: 0.8)
        case "Любовь": return Color(red: 1.0, green: 0.5, blue: 0.65)
        case "Старт": return Color(red: 0.95, green: 0.75, blue: 0.3)
        default: return Color(red: 0.7, green: 0.4, blue: 0.8)
        }
    }
    
    private var topBar: some View {
        HStack {
            Button(action: {
                if audioPlayer.nowPlayingID == item.id {
                    audioPlayer.stop()
                }
                dismiss()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 38, height: 38)
                    
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.6)
                        .frame(width: 38, height: 38)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.82))
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showAmbientPicker.toggle()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(selectedAmbient != .none ? 0.12 : 0.08))
                            .frame(width: 38, height: 38)
                        
                        Image(systemName: selectedAmbient.icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.82))
                    }
                }
                
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showDescription.toggle()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(showDescription ? 0.12 : 0.08))
                            .frame(width: 38, height: 38)
                        
                        Image(systemName: showDescription ? "info.circle.fill" : "info.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.82))
                    }
                }
            }
        }
    }
    
    private var descriptionCard: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text(item.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Для тех, кто хочет:")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    
                    ForEach(item.benefits, id: \.self) { benefit in
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(orbColor)
                                .frame(width: 6, height: 6)
                                .padding(.top, 7)
                            
                            Text(benefit)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.white.opacity(0.85))
                                .lineSpacing(4)
                        }
                    }
                }
                
                Text(item.fullDescription)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.75))
                    .lineSpacing(6)
                    .padding(.top, 8)
            }
            .padding(24)
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 0.6)
                )
        )
    }
    
    private var contentArea: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                orbColor.opacity(0.4),
                                orbColor.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 60,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)
                    .blur(radius: 30)
                    .scaleEffect(isPlaying ? 1.1 : 1.0)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                secondaryOrbColor.opacity(0.6),
                                orbColor.opacity(0.4),
                                orbColor.opacity(0.1)
                            ],
                            center: UnitPoint(x: 0.4, y: 0.4),
                            startRadius: 20,
                            endRadius: 110
                        )
                    )
                    .frame(width: 220, height: 220)
                    .blur(radius: 20)
                    .rotationEffect(.degrees(orbPhase * 360))
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                orbColor.opacity(0.7),
                                secondaryOrbColor.opacity(0.5)
                            ],
                            center: UnitPoint(x: 0.3, y: 0.3),
                            startRadius: 10,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.25),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: orbColor.opacity(0.5), radius: 40, x: 0, y: 20)
                
                Image(systemName: item.icon)
                    .font(.system(size: 56, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.95))
            }
            .scaleEffect(isPlaying ? 1.0 : 0.95)
            .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: isPlaying)
            
            VStack(spacing: 10) {
                Text(item.title)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 10) {
                    Text(item.category)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.65))
                    
                    Text("•")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.45))
                    
                    Text(item.duration)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.65))
                }
            }
            
            VStack(spacing: 12) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 5)
                        
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        orbColor,
                                        secondaryOrbColor
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: progressWidth(in: geo.size.width), height: 5)
                            .shadow(color: orbColor.opacity(0.6), radius: 8, x: 0, y: 0)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 14, height: 14)
                            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                            .offset(x: progressWidth(in: geo.size.width) - 7)
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                isDragging = true
                                let percent = max(0, min(1, value.location.x / geo.size.width))
                                currentTime = percent * duration
                            }
                            .onEnded { value in
                                let percent = max(0, min(1, value.location.x / geo.size.width))
                                let newTime = percent * duration
                                currentTime = newTime
                                audioPlayer.seek(to: newTime)
                                isDragging = false
                            }
                    )
                }
                .frame(height: 24)
                
                HStack {
                    Text(timeString(currentTime))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                    
                    Spacer()
                    
                    Text(timeString(duration))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
        }
    }
    
    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        let safeDuration = max(duration, 0.1)
        let progress = max(0, min(1, currentTime / safeDuration))
        return totalWidth * CGFloat(progress)
    }
    
    private var controlsArea: some View {
        HStack(spacing: 50) {
            Button(action: { seekBackward() }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 54, height: 54)
                    
                    Image(systemName: "gobackward.15")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Button(action: {
                audioPlayer.togglePlay(item: item)
                if audioPlayer.isPlaying, selectedAmbient != .none {
                    playAmbientSound()
                    startParticleAnimation()
                } else {
                    pauseAmbientSound()
                    particleTimer?.invalidate()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white,
                                    Color(red: 0.96, green: 0.96, blue: 0.98)
                                ],
                                center: .topLeading,
                                startRadius: 10,
                                endRadius: 50
                            )
                        )
                        .frame(width: 78, height: 78)
                        .shadow(color: Color.white.opacity(0.4), radius: 24, x: 0, y: 10)
                        .shadow(color: orbColor.opacity(0.3), radius: 30, x: 0, y: 12)
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(.black)
                        .offset(x: isPlaying ? 0 : 3)
                }
            }
            .scaleEffect(isPlaying ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.18), value: isPlaying)
            
            Button(action: { seekForward() }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 54, height: 54)
                    
                    Image(systemName: "goforward.15")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }
    
    private var ambientSoundPicker: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showAmbientPicker = false
                    }
                }
            
            VStack(spacing: 20) {
                Text("Фоновые звуки")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                VStack(spacing: 12) {
                    ForEach(AmbientSound.allCases) { sound in
                        Button(action: {
                            selectedAmbient = sound
                            if sound != .none, isPlaying {
                                playAmbientSound()
                                startParticleAnimation()
                            } else {
                                stopAmbientSound()
                                particleTimer?.invalidate()
                                particles.removeAll()
                            }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showAmbientPicker = false
                            }
                        }) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(selectedAmbient == sound ? 0.15 : 0.08))
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: sound.icon)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                
                                Text(sound.rawValue)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                if selectedAmbient == sound {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(orbColor)
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(selectedAmbient == sound ? 0.08 : 0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Color.white.opacity(selectedAmbient == sound ? 0.15 : 0.08), lineWidth: 0.6)
                                    )
                            )
                        }
                        .buttonStyle(PressScaleButtonStyle())
                    }
                }
                
                if selectedAmbient != .none {
                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "speaker.wave.1.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Slider(value: Binding(
                                get: { Double(ambientVolume) },
                                set: { newValue in
                                    ambientVolume = Float(newValue)
                                    ambientPlayer?.volume = ambientVolume
                                }
                            ), in: 0...0.3)
                            .tint(orbColor)
                            
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Text("Громкость: \(Int(ambientVolume * 100 / 0.3))%")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 18)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.08, blue: 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 0.6)
                    )
            )
            .padding(.horizontal, 20)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
    }
    
    private func setupAudio() {
        timer?.invalidate()
        timer = nil

        syncTimeline()

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard self.isActive else { return }
            guard !self.isDragging, let player = self.audioPlayer.player else { return }

            self.duration = max(player.duration, 0.1)
            self.currentTime = player.currentTime

            if player.isPlaying == false, self.currentTime >= self.duration - 0.05 {
                self.stopAmbientSound()
                self.particleTimer?.invalidate()
            }
        }
    }
    
    private func startOrbAnimation() {
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            orbPhase = 1.0
        }
    }
    
    private func playAmbientSound() {
        guard selectedAmbient != .none else { return }
        
        stopAmbientSound()
        
        let fileName = selectedAmbient.fileName
        let (name, ext) = splitNameExt(fileName)
        
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) ??
              Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resources") else {
            return
        }
        
        do {
            ambientPlayer = try AVAudioPlayer(contentsOf: url)
            ambientPlayer?.numberOfLoops = -1
            ambientPlayer?.volume = ambientVolume
            ambientPlayer?.prepareToPlay()
            ambientPlayer?.play()
        } catch {
            print("Ambient sound error: \(error)")
        }
    }
    
    private func pauseAmbientSound() {
        ambientPlayer?.pause()
        birdWingTimer?.invalidate()
        birdWingTimer = nil
    }

    private func stopAmbientSound() {
        ambientPlayer?.stop()
        ambientPlayer = nil
        birdWingTimer?.invalidate()
        birdWingTimer = nil
    }
    
    private func startParticleAnimation() {
        particleTimer?.invalidate()
        particles.removeAll()
        
        guard selectedAmbient != .none, isPlaying else { return }
        
        if selectedAmbient == .birds {
            birdWingTimer?.invalidate()
            birdWingTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
                DispatchQueue.main.async {
                    guard !particles.isEmpty else { return }
                    for i in particles.indices {
                        particles[i].wingFlap = (particles[i].wingFlap == 20 ? -20 : 20)
                    }
                }
            }
        }
        
        // Создаем новые частицы с интервалом
        particleTimer = Timer.scheduledTimer(withTimeInterval: particleInterval, repeats: true) { _ in
            guard self.isPlaying, self.selectedAmbient != .none else { return }
            self.addNewParticle()
        }
    }
    
    private var particleInterval: Double {
        switch selectedAmbient {
        case .birds: return 2.0
        case .ocean: return 1.5
        case .rain: return 0.15
        case .none: return 0
        }
    }
    
    private func addNewParticle() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        let particle = AmbientParticle(
            id: UUID(),
            x: particleStartX(screenWidth),
            y: particleStartY(screenHeight),
            size: 12,
            opacity: particleOpacity,
            rotation: CGFloat.random(in: 0...360),
            wingFlap: 0,
            scale: 0.5
        )
        
        particles.append(particle)
        animateParticle(particle: particle, screenWidth: screenWidth, screenHeight: screenHeight)
        
        // Удаляем старые частицы
        if particles.count > maxParticles {
            particles.removeFirst()
        }
    }
    
    private var maxParticles: Int {
        switch selectedAmbient {
        case .birds: return 6
        case .ocean: return 10
        case .rain: return 30
        case .none: return 0
        }
    }
    
    private var particleOpacity: Double {
        switch selectedAmbient {
        case .birds: return Double.random(in: 0.5...0.8)
        case .ocean: return Double.random(in: 0.3...0.6)
        case .rain: return Double.random(in: 0.4...0.7)
        case .none: return 0
        }
    }
    
    private func particleStartX(_ screenWidth: CGFloat) -> CGFloat {
        switch selectedAmbient {
        case .birds: return CGFloat.random(in: -screenWidth/2...screenWidth/2)
        case .ocean: return CGFloat.random(in: -screenWidth/2...screenWidth/2)
        case .rain: return CGFloat.random(in: -screenWidth/2...screenWidth/2)
        case .none: return 0
        }
    }
    
    private func particleStartY(_ screenHeight: CGFloat) -> CGFloat {
        switch selectedAmbient {
        case .birds: return screenHeight/2 + 50
        case .ocean: return CGFloat.random(in: -screenHeight/3...screenHeight/3)
        case .rain: return -screenHeight/2 - 50
        case .none: return 0
        }
    }
    
    private func animateParticle(particle: AmbientParticle, screenWidth: CGFloat, screenHeight: CGFloat) {
        guard let index = particles.firstIndex(where: { $0.id == particle.id }) else { return }
        
        switch selectedAmbient {
        case .birds:
            withAnimation(.linear(duration: 8)) {
                particles[index].y = -screenHeight/2 - 100
                particles[index].x += CGFloat.random(in: -150...150)
            }
        case .ocean:
            // Волны расширяются и исчезают
            withAnimation(.easeOut(duration: 3)) {
                particles[index].scale = 2.0
                particles[index].opacity = 0
            }
            
        case .rain:
            // Капли падают вертикально вниз
            withAnimation(.linear(duration: 1.5)) {
                particles[index].y = screenHeight/2 + 100
                particles[index].x += CGFloat.random(in: -10...10)
            }
            
        case .none:
            break
        }
        
        // Удаляем частицу после анимации
        DispatchQueue.main.asyncAfter(deadline: .now() + particleDuration) {
            if let idx = self.particles.firstIndex(where: { $0.id == particle.id }) {
                self.particles.remove(at: idx)
            }
        }
    }
    
    private var particleDuration: Double {
        switch selectedAmbient {
        case .birds: return 8
        case .ocean: return 3
        case .rain: return 1.5
        case .none: return 0
        }
    }
    
    private func splitNameExt(_ filename: String) -> (String, String?) {
        let comps = filename.split(separator: ".", omittingEmptySubsequences: false)
        guard comps.count >= 2 else { return (filename, nil) }
        let name = comps.dropLast().joined(separator: ".")
        let ext = String(comps.last ?? "")
        return (String(name), ext.isEmpty ? nil : ext)
    }
    
    private func seekBackward() {
        let newTime = max(0, currentTime - 15)
        currentTime = newTime
        audioPlayer.seek(to: newTime)
    }
    
    private func seekForward() {
        let newTime = min(duration, currentTime + 15)
        currentTime = newTime
        audioPlayer.seek(to: newTime)
    }
    
    private func timeString(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Ambient Particle Model

struct AmbientParticle: Identifiable, Equatable {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var rotation: CGFloat
    var wingFlap: CGFloat
    var scale: CGFloat
    
    static func == (lhs: AmbientParticle, rhs: AmbientParticle) -> Bool {
        lhs.id == rhs.id
    }
}

private struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
