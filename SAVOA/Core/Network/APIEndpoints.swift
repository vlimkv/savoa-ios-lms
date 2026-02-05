//
//  APIEndpoints.swift
//  PelvicFloorApp
//
//  Created by 7Я on 04.12.2025.
//

import Foundation

struct APIEndpoints {
    static let baseURL = "https://YOUR_PRODUCTION_API_URL/api"

    // Health
    static let health = "/health"

    // Auth
    static let login = "/auth/login"
    static let forgotPassword = "/auth/forgot-password"
    static let resetPassword = "/auth/reset-password"

    // Account
    static let me = "/me"
    static let attachEmail = "/me/attach-email"
    
    // User
    static let userProfile = "/user/profile"
    static let updateProfile = "/user/profile"
    
    // Course
    static let courseContent = "/course/content"
    static let lessonDetail = "/lessons" // + /{id}
    static let theoryLessons = "/theory-lessons"
    
    // Progress
    static let syncProgress = "/progress/sync"
    static let updateProgress = "/progress/update"
    
    // Journal
    static let journalEntries = "/journal/entries"
    static let createEntry = "/journal/create"
    
    // Library
    static let libraryContent = "/library/articles"
}
