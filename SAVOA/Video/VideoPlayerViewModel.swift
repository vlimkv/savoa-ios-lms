//
//  VideoPlayerViewModel.swift
//  PelvicFloorApp
//
//  Stable Video ViewModel - Swift 6 Concurrency Safe (No Task hops in @Sendable closures)
//

import SwiftUI
import AVKit
import Combine

@MainActor
final class VideoPlayerViewModel: ObservableObject {
    // MARK: - Published

    @Published var player: AVPlayer?
    @Published var state: PlayerState = .loading
    @Published var isPlaying = false
    @Published var isCompleted = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isBuffering = false
    @Published var showControls: Bool = true

    // MARK: - Private

    private let lesson: Lesson
    private let apiClient: APIClient
    private let storage: StorageServiceProtocol
    private let progressService: ProgressService

    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private var heartbeatTask: Task<Void, Never>?
    private var lastReportedTime: Double = 0
    private var isScrubbing = false
    private var isCleanedUp = false

    enum PlayerState: Equatable {
        case loading
        case ready
        case error(String)
    }

    // MARK: - Init

    init(
        lesson: Lesson,
        progressService: ProgressService? = nil,
        apiClient: APIClient? = nil,
        storage: StorageServiceProtocol? = nil
    ) {
        self.lesson = lesson
        self.progressService = progressService ?? .shared
        self.apiClient = apiClient ?? .shared
        self.storage = storage ?? StorageService.shared
    }

    // MARK: - Public

    func loadVideo() async {
        guard player == nil, !isCleanedUp else { return }

        state = .loading
        setupAudioSession()

        do {
            guard let token = storage.loadFromKeychain(forKey: StorageService.Keys.authToken) else {
                throw VideoError.unauthorized
            }

            await syncProgress(token: token)
            let url = try await fetchVideoURL(token: token)

            let asset = AVURLAsset(url: url)
            if let dur = try? await asset.load(.duration) {
                let sec = CMTimeGetSeconds(dur)
                if sec.isFinite && sec > 0 { duration = sec }
            }

            let item = AVPlayerItem(asset: asset)
            let newPlayer = AVPlayer(playerItem: item)
            newPlayer.automaticallyWaitsToMinimizeStalling = true
            newPlayer.actionAtItemEnd = .pause

            if currentTime > 5, duration > 0, currentTime < duration - 10 {
                await newPlayer.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600))
            }

            player = newPlayer
            setupObservers(player: newPlayer)
            setupHeartbeat()
            state = .ready

        } catch {
            print("❌ Video error: \(error)")
            state = .error((error as? VideoError)?.localizedDescription ?? "Ошибка загрузки")
        }
    }

    func cleanup() {
        guard !isCleanedUp else { return }
        isCleanedUp = true

        heartbeatTask?.cancel()
        cancellables.removeAll()

        if let obs = timeObserver, let p = player {
            p.removeTimeObserver(obs)
        }
        timeObserver = nil

        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil

        Task { [weak self] in
            await self?.sendProgress()
        }
    }

    func togglePlayPause() {
        guard let player else { return }
        if isPlaying {
            player.pause()
        } else {
            if currentTime >= duration - 1 {
                player.seek(to: .zero)
            }
            player.play()
        }
    }

    func seek(to time: Double, isScrubbing: Bool) {
        self.isScrubbing = isScrubbing

        let target = max(0, min(time, duration))
        currentTime = target

        guard let player else { return }
        let cm = CMTime(seconds: target, preferredTimescale: 600)

        if isScrubbing {
            player.seek(to: cm, toleranceBefore: .zero, toleranceAfter: .zero)
        } else {
            player.seek(to: cm, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
                // completion может быть @Sendable — но мы НЕ прыгаем в Task
                // просто гарантируем main + изолируемся как MainActor
                DispatchQueue.main.async {
                    guard let self else { return }
                    MainActor.assumeIsolated {
                        self.isScrubbing = false
                    }
                }
            }
        }
    }

    // MARK: - Private

    private func setupObservers(player: AVPlayer) {
        // 1) timeControlStatus: сначала на main queue, потом assumeIsolated
        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                MainActor.assumeIsolated {
                    self.isPlaying = (status == .playing)
                    self.isBuffering = (status == .waitingToPlayAtSpecifiedRate)
                }
            }
            .store(in: &cancellables)

        // 2) periodic time observer: у нас queue: .main
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            MainActor.assumeIsolated {
                guard !self.isScrubbing else { return }
                let sec = CMTimeGetSeconds(time)
                if sec.isFinite {
                    self.currentTime = sec
                    self.checkCompletion()
                }
            }
        }

        // 3) end notification: тоже на main queue
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                MainActor.assumeIsolated {
                    self.handleEnd()
                }
            }
            .store(in: &cancellables)
    }

    private func checkCompletion() {
        guard duration > 0, !isCompleted, currentTime / duration > 0.95 else { return }
        markCompleted()
        progressService.updateLessonPosition(lesson.id, position: currentTime)
    }

    private func markCompleted() {
        guard !isCompleted else { return }
        isCompleted = true
        progressService.markLessonCompleted(lesson.id)
        Task { await sendProgress() }
    }

    private func handleEnd() {
        isPlaying = false
        markCompleted()
    }

    private func fetchVideoURL(token: String) async throws -> URL {
        struct Resp: Codable { let cloudflare: CF }
        struct CF: Codable { let token: String; let playback: PB? }
        struct PB: Codable { let hls: String? }

        let r: Resp = try await apiClient.request("/lessons/\(lesson.id)/play", method: "GET", token: token)
        guard let hls = r.cloudflare.playback?.hls else { throw VideoError.noPlaybackURL }
        guard let url = URL(string: "\(hls)?token=\(r.cloudflare.token)") else { throw VideoError.invalidURL }
        return url
    }

    private func syncProgress(token: String) async {
        struct ProgressResponse: Codable { let progress: [ProgressItem] }
        struct ProgressItem: Codable {
            let lesson_id: String
            let seconds_watched: Int
            let completed: Bool
        }

        do {
            let response: ProgressResponse = try await apiClient.request("/progress", method: "GET", token: token)

            if let item = response.progress.first(where: { $0.lesson_id == lesson.id }) {
                currentTime = Double(item.seconds_watched)
                isCompleted = item.completed

                progressService.updateLessonPosition(lesson.id, position: currentTime)
                if item.completed {
                    progressService.markLessonCompleted(lesson.id)
                }
            } else {
                loadLocal()
            }
        } catch {
            print("⚠️ Failed to sync progress from API: \(error)")
            loadLocal()
        }
    }

    private func loadLocal() {
        if let p = progressService.getLessonProgress(lesson.id) {
            isCompleted = (p.state == .completed)
            currentTime = p.lastPosition
        }
    }

    private func setupHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                guard !Task.isCancelled else { break }
                if abs(self.currentTime - self.lastReportedTime) > 10 {
                    await self.sendProgress()
                }
            }
        }
    }

    private func sendProgress() async {
        guard let token = storage.loadFromKeychain(forKey: StorageService.Keys.authToken) else { return }
        lastReportedTime = currentTime

        struct Body: Codable { let seconds_watched: Int; let completed: Bool }
        struct Empty: Codable {}

        let _: Empty? = try? await apiClient.request(
            "/lessons/\(lesson.id)/progress",
            method: "POST",
            token: token,
            body: Body(seconds_watched: Int(currentTime), completed: isCompleted)
        )
    }

    private func setupAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
}

enum VideoError: Error, LocalizedError {
    case unauthorized, noPlaybackURL, invalidURL

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Требуется авторизация"
        case .noPlaybackURL: return "Видео недоступно"
        case .invalidURL: return "Ошибка ссылки"
        }
    }
}
