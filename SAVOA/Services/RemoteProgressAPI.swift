//
//  RemoteProgressAPI.swift
//  SAVOA
//
//  Created by 7Я on 08.01.2026.
//

import Foundation

// MARK: - DTOs

struct BackendProgressResponse: Decodable {
    let progress: [BackendLessonProgress]
}

struct BackendLessonProgress: Decodable {
    let lesson_id: String
    let seconds_watched: Int
    let completed: Bool
    let updated_at: String?
}

struct ProgressPushBody: Encodable {
    let seconds_watched: Int
    let completed: Bool?
}

// MARK: - Token Provider

protocol AuthTokenProvider {
    func getToken() -> String?
}

final class KeychainTokenProvider: AuthTokenProvider {
    private let storage: StorageServiceProtocol
    init(storage: StorageServiceProtocol = StorageService.shared) {
        self.storage = storage
    }

    func getToken() -> String? {
        storage.loadFromKeychain(forKey: StorageService.Keys.authToken)
    }
}

// MARK: - API

final class RemoteProgressAPI {

    enum APIError: Error {
        case invalidURL
        case noToken
        case unauthorized
        case badStatus(Int, Data?)
        case decoding(Error)
        case encoding(Error)
    }

    private let baseURL: URL
    private let tokenProvider: AuthTokenProvider
    private let session: URLSession

    init(
        baseURLString: String = APIEndpoints.baseURL,
        tokenProvider: AuthTokenProvider = KeychainTokenProvider(),
        session: URLSession = .shared
    ) throws {
        guard let url = URL(string: baseURLString) else { throw APIError.invalidURL }
        self.baseURL = url
        self.tokenProvider = tokenProvider
        self.session = session
    }

    func fetchProgress() async throws -> [BackendLessonProgress] {
        let req = try makeRequest(path: "/progress", method: "GET", jsonBody: Optional<Int>.none)
        let (data, resp) = try await session.data(for: req)
        try validate(resp: resp, data: data)

        do {
            return try JSONDecoder().decode(BackendProgressResponse.self, from: data).progress
        } catch {
            throw APIError.decoding(error)
        }
    }

    func pushProgress(lessonId: String, secondsWatched: Int, completed: Bool? = nil) async throws {
        let body = ProgressPushBody(seconds_watched: secondsWatched, completed: completed)
        let req = try makeRequest(path: "/lessons/\(lessonId)/progress", method: "POST", jsonBody: body)
        let (data, resp) = try await session.data(for: req)
        try validate(resp: resp, data: data)
    }

    // MARK: - Helpers

    private func makeRequest<T: Encodable>(path: String, method: String, jsonBody: T?) throws -> URLRequest {
        guard let token = tokenProvider.getToken(), !token.isEmpty else { throw APIError.noToken }

        let clean = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let url = baseURL.appendingPathComponent(clean)

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        if let jsonBody {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                req.httpBody = try JSONEncoder().encode(jsonBody)
            } catch {
                throw APIError.encoding(error)
            }
        }
        return req
    }

    private func validate(resp: URLResponse, data: Data?) throws {
        guard let http = resp as? HTTPURLResponse else { return }
        if http.statusCode == 401 { throw APIError.unauthorized }
        if !(200...299).contains(http.statusCode) { throw APIError.badStatus(http.statusCode, data) }
    }
}
