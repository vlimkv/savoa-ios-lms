//
//  User.swift
//  PelvicFloorApp
//
//  Created by 7Я on 04.12.2025.
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let login: String?
    let firstName: String
    let lastName: String
    let avatarURL: String?
    let registeredAt: Date

    let tariffId: String?
    let accessEnd: String?

    var fullName: String { "\(firstName) \(lastName)" }

    var displayName: String {
        if let l = login?.trimmingCharacters(in: .whitespacesAndNewlines), !l.isEmpty {
            return l
        }
        let fn = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !fn.isEmpty { return fn }
        return email.split(separator: "@").first.map(String.init) ?? email
    }

    enum CodingKeys: String, CodingKey {
        case id
        case login = "login"
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case avatarURL = "avatar_url"
        case registeredAt = "created_at"
        case tariffId = "tariff_id"
        case accessEnd = "access_end"
    }
}
