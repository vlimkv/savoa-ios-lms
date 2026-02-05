//
//  AuthService.swift
//  PelvicFloorApp
//
//  Created by 7Я on 04.12.2025.
//

import Foundation

protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> User
    func logout()
    func getCurrentUser() -> User?
    func isAuthenticated() -> Bool
    func requestPasswordReset(email: String) async throws
}

final class AuthService: AuthServiceProtocol {
    static let shared = AuthService()

    private let networkService: NetworkServiceProtocol
    private let storage: StorageServiceProtocol

    private var currentUser: User?
    private var authToken: String?

    private init() {
        self.networkService = RealNetworkService.shared
        self.storage = StorageService.shared

        self.authToken = storage.loadFromKeychain(forKey: StorageService.Keys.authToken)
        self.currentUser = storage.load(User.self, forKey: StorageService.Keys.currentUser)

        // если токен был сохранён — прокинем в сеть, чтобы /me работал
        if let token = self.authToken, let real = networkService as? RealNetworkService {
            real.setAuthToken(token)
        }
    }

    func login(email: String, password: String) async throws -> User {
        do {
            // 1) token
            let tokenResp = try await networkService.loginToken(login: email, password: password)

            // 2) set token for next requests
            if let real = networkService as? RealNetworkService {
                real.setAuthToken(tokenResp.token)
            }

            // 3) /me
            let me = try await networkService.fetchMe()

            // 4) map -> User (registeredAt: Date)
            let safeEmail = me.email ?? email
            let registeredAt = parseServerDate(me.createdAt) ?? Date()

            let user = User(
              id: me.id,
              email: safeEmail,
              login: me.login,
              firstName: "",
              lastName: "",
              avatarURL: nil,
              registeredAt: registeredAt,
              tariffId: me.tariffId,
              accessEnd: me.accessEnd
            )

            // 5) persist
            self.authToken = tokenResp.token
            self.currentUser = user

            storage.saveToKeychain(tokenResp.token, forKey: StorageService.Keys.authToken)
            storage.save(user, forKey: StorageService.Keys.currentUser)

            return user

        } catch let e as NetworkError {
            switch e {
            case .unauthorized:
                throw AuthError.invalidCredentials
            case .decodingError:
                throw AuthError.parsing
            case .transport:
                throw AuthError.connection
            case .serverError(_, let msg):
                throw AuthError.server(msg ?? "Ошибка сервера")
            default:
                throw AuthError.unknown
            }
        } catch {
            throw AuthError.unknown
        }
    }

    func requestPasswordReset(email: String) async throws {
        do {
            let resp = try await networkService.forgotPassword(email: email)
            if resp.ok != true {
                throw AuthError.unknown
            }
        } catch let e as NetworkError {
            switch e {
            case .transport:
                throw AuthError.connection
            case .serverError(_, let msg):
                throw AuthError.server(msg ?? "Не удалось отправить письмо")
            default:
                throw AuthError.unknown
            }
        } catch {
            throw AuthError.unknown
        }
    }
    
    func getToken() -> String? {
        authToken
    }

    func logout() {
        self.authToken = nil
        self.currentUser = nil

        storage.removeFromKeychain(forKey: StorageService.Keys.authToken)
        storage.remove(forKey: StorageService.Keys.currentUser)

        storage.remove(forKey: StorageService.Keys.progress)
        storage.remove(forKey: StorageService.Keys.journalEntries)

        if let real = networkService as? RealNetworkService {
            real.setAuthToken("")
        }
    }

    func getCurrentUser() -> User? {
        currentUser
    }

    func isAuthenticated() -> Bool {
        authToken != nil && currentUser != nil
    }

    // MARK: - Date parsing

    private func parseServerDate(_ s: String?) -> Date? {
        guard let s, !s.isEmpty else { return nil }

        // 1) ISO8601 (самый частый)
        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: s) { return d }

        // 2) Postgres timestamp типа "2025-12-27 12:34:56.123+00"
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSXXXXX"
        if let d = df.date(from: s) { return d }

        // 3) иногда без миллисекунд
        df.dateFormat = "yyyy-MM-dd HH:mm:ssXXXXX"
        if let d = df.date(from: s) { return d }

        return nil
    }
}
