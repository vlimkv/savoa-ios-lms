//
//  BreathSoundManager.swift
//  PelvicFloorApp
//
//  Created by 7Я on 10.12.2025.
//

import Foundation
import AVFoundation

/// Отвечает за звуки вдоха, выдоха и сердцебиения в практиках дыхания.
final class BreathSoundManager {
    static let shared = BreathSoundManager()
    
    private var inhalePlayer: AVAudioPlayer?
    private var exhalePlayer: AVAudioPlayer?
    private var heartbeatPlayer: AVAudioPlayer?
    
    private init() {
        setupAudioSession()
        
        inhalePlayer = loadPlayer(named: "inhale", type: "wav")
        exhalePlayer = loadPlayer(named: "exhale", type: "wav")
        heartbeatPlayer = loadPlayer(named: "heartbeat", type: "wav", loop: true)
        
        inhalePlayer?.volume = 0.9
        exhalePlayer?.volume = 0.9
        heartbeatPlayer?.volume = 0.8
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("AudioSession error: \(error)")
        }
    }
    
    private func loadPlayer(named name: String, type: String, loop: Bool = false) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: type) else {
            print("⚠️ Sound file \(name).\(type) not found")
            return nil
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            if loop {
                player.numberOfLoops = -1
            }
            player.prepareToPlay()
            return player
        } catch {
            print("⚠️ Failed to load \(name): \(error)")
            return nil
        }
    }
    
    // MARK: - Public API
    
    func playInhale() {
        inhalePlayer?.currentTime = 0
        inhalePlayer?.play()
    }
    
    func playExhale() {
        exhalePlayer?.currentTime = 0
        exhalePlayer?.play()
    }
    
    func startHeartbeat() {
        heartbeatPlayer?.currentTime = 0
        heartbeatPlayer?.play()
    }
    
    func stopHeartbeat() {
        heartbeatPlayer?.stop()
    }
    
    func stopAll() {
        inhalePlayer?.stop()
        exhalePlayer?.stop()
        heartbeatPlayer?.stop()
    }
}
