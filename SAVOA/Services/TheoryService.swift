//
//  TheoryService.swift
//  SAVOA
//
//  Created by 7Я on 10.01.2026.
//

import Foundation

final class TheoryService {
    static let shared = TheoryService()
    private init() {}

    func fetchTheoryLessons(token: String) async throws -> [TheoryLessonDTO] {
        try await APIClient.shared.request(
            APIEndpoints.theoryLessons,
            method: "GET",
            token: token
        )
    }
}
