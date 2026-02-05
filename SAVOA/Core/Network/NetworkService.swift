//
//  NetworkService.swift
//  PelvicFloorApp
//
//  Created by 7Я on 04.12.2025.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case decodingError
    case serverError(Int, String?)
    case unauthorized
    case transport(String)
    case unknown
}

protocol NetworkServiceProtocol {
    func request<T: Decodable>(
        endpoint: String,
        method: String,
        body: [String: Any]?,
        headers: [String: String]?
    ) async throws -> T

    func loginToken(login: String, password: String) async throws -> LoginTokenResponse
    func fetchMe() async throws -> MeResponse
    func forgotPassword(email: String) async throws -> OkResponse
}

final class RealNetworkService: NetworkServiceProtocol {
    static let shared = RealNetworkService()

    private let session = URLSession.shared
    private var authToken: String?

    private init() {}

    func setAuthToken(_ token: String) {
        self.authToken = token
    }

    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {

        guard let url = URL(string: APIEndpoints.baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let shouldAttachAuth = (headers?["Authorization"] == nil)

        if shouldAttachAuth, let token = authToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw NetworkError.unknown
            }

            if !(200...299).contains(http.statusCode) {
                let raw = String(data: data, encoding: .utf8)
                print("❌ \(method) \(url.absoluteString) -> \(http.statusCode)")
                print("❌ BODY:", raw ?? "<no-body>")

                if http.statusCode == 401 { throw NetworkError.unauthorized }
                throw NetworkError.serverError(http.statusCode, raw)
            }

            if data.isEmpty {
                if let emptyOK = OkResponse(ok: true) as? T {
                    return emptyOK
                }
                throw NetworkError.decodingError
            }

            do {
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch {
                let raw = String(data: data, encoding: .utf8)
                print("❌ DECODE FAIL \(method) \(url.absoluteString)")
                print("❌ BODY:", raw ?? "<no-body>")
                throw NetworkError.decodingError
            }

        } catch {
            print("❌ TRANSPORT:", error)
            print("❌ TRANSPORT desc:", error.localizedDescription)
            throw NetworkError.transport(error.localizedDescription)
        }
    }

    // MARK: - API

    func loginToken(login: String, password: String) async throws -> LoginTokenResponse {
        let body: [String: Any] = [
            "login": login,
            "password": password
        ]
        return try await request(endpoint: APIEndpoints.login, method: "POST", body: body, headers: nil)
    }

    func fetchMe() async throws -> MeResponse {
        return try await request(endpoint: APIEndpoints.me, method: "GET", body: nil, headers: nil)
    }

    func forgotPassword(email: String) async throws -> OkResponse {
        let body: [String: Any] = ["email": email]

        let headers: [String: String] = ["Authorization": ""]

        return try await request(endpoint: APIEndpoints.forgotPassword, method: "POST", body: body, headers: headers)
    }
}
