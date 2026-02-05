//
//  AuthModels.swift
//  SAVOA
//
//  Created by 7Я on 27.12.2025.
//

import Foundation

struct LoginRequest: Encodable {
    let login: String
    let password: String
}

struct LoginTokenResponse: Decodable {
    let token: String
}

struct MeResponse: Codable {
    let id: String
    let login: String?
    let email: String?
    let createdAt: String

    let tariffId: String?
    let accessEnd: String?
    let grantedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, login, email
        case createdAt = "created_at"

        case tariffId = "tariff_id"
        case accessEnd = "access_end"
        case grantedAt = "granted_at"
    }
}

struct OkResponse: Decodable {
    let ok: Bool
}

struct ForgotPasswordRequest: Encodable {
    let email: String
}
