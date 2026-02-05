//
//  AudioMeditationPlayer.swift
//  PelvicFloorApp
//
//  Premium Audio Player for Meditations
//

import Foundation
import AVFoundation
import Combine
import MediaPlayer
import UIKit

final class AudioMeditationPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var nowPlayingID: UUID? = nil
    @Published var isPlaying: Bool = false

    var player: AVAudioPlayer?

    private var nowPlayingTimer: Timer?
    private var lastTitle: String = "Meditation"
    private var lastSubtitle: String = "SAVOA"
    private var lastArtworkName: String? = "NowPlayingArtwork" // положи картинку в Assets с таким именем

    override init() {
        super.init()
        configureAudioSession()
        configureRemoteCommands()
    }

    // MARK: - Public API

    func togglePlay(item: MeditationItem) {
        if nowPlayingID == item.id {
            isPlaying ? pause() : resume()
            return
        }
        play(item: item)
    }

    func play(item: MeditationItem) {
        if nowPlayingID == item.id, player != nil {
            resume()
            return
        }

        guard let url = resolveAudioURL(from: item.audioFileName) else {
            nowPlayingID = item.id
            isPlaying = false
            return
        }

        do {
            configureAudioSession()

            player?.stop()
            player = nil

            let p = try AVAudioPlayer(contentsOf: url)
            p.delegate = self
            p.prepareToPlay()
            p.play()

            player = p
            nowPlayingID = item.id
            isPlaying = true

            lastTitle = item.title
            lastSubtitle = "SAVOA • \(item.category) • \(item.duration)"
            // если хочешь на каждую категорию разную обложку:
            // lastArtworkName = artworkName(for: item.category)
            lastArtworkName = "NowPlayingArtwork"

            startNowPlayingTimer()
            updateNowPlayingInfo()

        } catch {
            print("Audio play error:", error)
            nowPlayingID = item.id
            isPlaying = false
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }

    func resume() {
        guard let player else { return }
        configureAudioSession()
        player.play()
        isPlaying = true
        startNowPlayingTimer()
        updateNowPlayingInfo()
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        nowPlayingID = nil

        stopNowPlayingTimer()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil

        do { try AVAudioSession.sharedInstance().setActive(false, options: []) } catch { }
    }

    func seek(to time: Double) {
        guard let player else { return }
        player.currentTime = max(0, min(time, player.duration))
        updateNowPlayingInfo()
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        stopNowPlayingTimer()
        updateNowPlayingInfo()
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true, options: [])
        } catch {
            print("AudioSession error:", error)
        }
    }

    // MARK: - Now Playing + Artwork

    private func startNowPlayingTimer() {
        stopNowPlayingTimer()
        nowPlayingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateNowPlayingInfo()
        }
        RunLoop.main.add(nowPlayingTimer!, forMode: .common)
    }

    private func stopNowPlayingTimer() {
        nowPlayingTimer?.invalidate()
        nowPlayingTimer = nil
    }

    private func updateNowPlayingInfo() {
        guard let player else { return }

        let elapsed = player.currentTime
        let duration = player.duration
        let rate: Double = isPlaying ? 1.0 : 0.0

        DispatchQueue.main.async {
            var info: [String: Any] = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]

            info[MPMediaItemPropertyTitle] = self.lastTitle
            info[MPMediaItemPropertyArtist] = "SAVOA"
            info[MPMediaItemPropertyAlbumTitle] = self.lastSubtitle

            info[MPMediaItemPropertyPlaybackDuration] = duration
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
            info[MPNowPlayingInfoPropertyPlaybackRate] = rate

            if let artwork = self.makeArtwork() {
                info[MPMediaItemPropertyArtwork] = artwork
            }

            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }

    private func makeArtwork() -> MPMediaItemArtwork? {
        guard let name = lastArtworkName else { return nil }

        // 1) Сначала пробуем из Assets
        if let img = UIImage(named: name) {
            return MPMediaItemArtwork(boundsSize: img.size) { _ in img }
        }

        // 2) Фолбэк: рендерим красивую “премиум-обложку” прямо кодом (градиент + логотип)
        let size = CGSize(width: 800, height: 800)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)

            // фон
            UIColor.black.setFill()
            ctx.fill(rect)

            // градиент 1
            let cg1 = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [UIColor(red: 0.10, green: 0.08, blue: 0.20, alpha: 1).cgColor,
                         UIColor(red: 0.02, green: 0.02, blue: 0.04, alpha: 1).cgColor] as CFArray,
                locations: [0, 1]
            )
            if let cg1 {
                ctx.cgContext.drawRadialGradient(
                    cg1,
                    startCenter: CGPoint(x: size.width * 0.25, y: size.height * 0.30),
                    startRadius: 50,
                    endCenter: CGPoint(x: size.width * 0.25, y: size.height * 0.30),
                    endRadius: 520,
                    options: []
                )
            }

            // градиент 2
            let cg2 = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [UIColor(red: 0.85, green: 0.65, blue: 0.25, alpha: 0.30).cgColor,
                         UIColor.clear.cgColor] as CFArray,
                locations: [0, 1]
            )
            if let cg2 {
                ctx.cgContext.drawRadialGradient(
                    cg2,
                    startCenter: CGPoint(x: size.width * 0.72, y: size.height * 0.62),
                    startRadius: 40,
                    endCenter: CGPoint(x: size.width * 0.72, y: size.height * 0.62),
                    endRadius: 520,
                    options: []
                )
            }

            // лёгкий “световой орб”
            ctx.cgContext.setFillColor(UIColor(white: 1.0, alpha: 0.08).cgColor)
            ctx.cgContext.fillEllipse(in: CGRect(x: 140, y: 160, width: 520, height: 520))

            // текст SAVOA
            let title = "SAVOA"
            let font = UIFont.systemFont(ofSize: 88, weight: .semibold)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor(white: 1.0, alpha: 0.92),
                .kern: 8
            ]
            let ts = title.size(withAttributes: attrs)
            let tx = (size.width - ts.width) / 2
            let ty = size.height * 0.60
            title.draw(at: CGPoint(x: tx, y: ty), withAttributes: attrs)

            // подпись Meditation
            let sub = "Meditation"
            let subFont = UIFont.systemFont(ofSize: 28, weight: .medium)
            let subAttrs: [NSAttributedString.Key: Any] = [
                .font: subFont,
                .foregroundColor: UIColor(white: 1.0, alpha: 0.55),
                .kern: 2
            ]
            let ss = sub.size(withAttributes: subAttrs)
            let sx = (size.width - ss.width) / 2
            let sy = ty + 110
            sub.draw(at: CGPoint(x: sx, y: sy), withAttributes: subAttrs)
        }

        return MPMediaItemArtwork(boundsSize: img.size) { _ in img }
    }

    // если хочешь разные обложки по категориям — добавь картинки в Assets:
    // "art_sleep", "art_love", "art_start"
    private func artworkName(for category: String) -> String {
        switch category {
        case "Сон": return "art_sleep"
        case "Любовь": return "art_love"
        case "Старт": return "art_start"
        default: return "NowPlayingArtwork"
        }
    }

    // MARK: - Remote Commands

    private func configureRemoteCommands() {
        UIApplication.shared.beginReceivingRemoteControlEvents()

        let center = MPRemoteCommandCenter.shared()

        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true
        center.togglePlayPauseCommand.isEnabled = true
        center.changePlaybackPositionCommand.isEnabled = true

        center.skipForwardCommand.isEnabled = true
        center.skipBackwardCommand.isEnabled = true
        center.skipForwardCommand.preferredIntervals = [15]
        center.skipBackwardCommand.preferredIntervals = [15]

        center.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.isPlaying ? self.pause() : self.resume()
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self,
                  let e = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self.seek(to: e.positionTime)
            return .success
        }
        center.skipForwardCommand.addTarget { [weak self] _ in
            guard let self, let p = self.player else { return .commandFailed }
            self.seek(to: p.currentTime + 15)
            return .success
        }
        center.skipBackwardCommand.addTarget { [weak self] _ in
            guard let self, let p = self.player else { return .commandFailed }
            self.seek(to: p.currentTime - 15)
            return .success
        }
    }

    // MARK: - File resolving

    private func resolveAudioURL(from fileNameOrPath: String) -> URL? {
        if fileNameOrPath.contains("/") {
            let parts = fileNameOrPath.split(separator: "/").map(String.init)
            let last = parts.last ?? fileNameOrPath
            let subdir = parts.dropLast().joined(separator: "/")

            let (name, ext) = splitNameExt(last)
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdir) {
                return url
            }
        }

        let (name, ext) = splitNameExt(fileNameOrPath)
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            return url
        }
        if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resources") {
            return url
        }
        return nil
    }

    private func splitNameExt(_ filename: String) -> (String, String?) {
        let comps = filename.split(separator: ".", omittingEmptySubsequences: false)
        guard comps.count >= 2 else { return (filename, nil) }
        let name = comps.dropLast().joined(separator: ".")
        let ext = String(comps.last ?? "")
        return (String(name), ext.isEmpty ? nil : ext)
    }
}
