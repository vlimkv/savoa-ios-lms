//
//  APIClient.swift
//  SAVOA
//
//  Created by 7Я on 27.12.2025.
//

import Foundation

enum APIError: Error {
    case badStatus(Int, String?)
    case decoding
    case transport
}

final class APIClient {
    static let shared = APIClient()
    private init() {}

    private let baseURL = URL(string: APIEndpoints.baseURL)!
    private let session = URLSession.shared

    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        token: String? = nil,
        body: Encodable? = nil
    ) async throws -> T {
        
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let url = baseURL.appendingPathComponent(cleanPath)

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }

        do {
            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse else {
                throw APIError.transport
            }

            if !(200...299).contains(http.statusCode) {
                let raw = String(data: data, encoding: .utf8)
                print("❌ API \(method) \(url.absoluteString) -> \(http.statusCode)")
                print("❌ BODY:", raw ?? "<no-body>")

                let msg = (try? JSONDecoder().decode(ServerError.self, from: data).error) ?? raw
                throw APIError.badStatus(http.statusCode, msg)
            }

            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                let raw = String(data: data, encoding: .utf8)
                print("❌ DECODE FAIL \(method) \(url.absoluteString)")
                print("❌ BODY:", raw ?? "<no-body>")
                throw APIError.decoding
            }
        } catch {
            print("❌ TRANSPORT \(method) \(url.absoluteString):", error.localizedDescription)
            throw APIError.transport
        }
    }
}

private struct ServerError: Decodable { let error: String? }

private struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    init(_ wrapped: Encodable) { self.encodeFunc = wrapped.encode }
    func encode(to encoder: Encoder) throws { try encodeFunc(encoder) }
}
