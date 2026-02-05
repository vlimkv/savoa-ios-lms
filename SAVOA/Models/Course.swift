//
//  Course.swift
//  PelvicFloorApp
//
//  Created by 7Я on 04.12.2025.
//

import Foundation

struct Course: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let modules: [Module]
    let authorName: String
    let authorBio: String
    let authorImageURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, modules
        case authorName = "author_name"
        case authorBio = "author_bio"
        case authorImageURL = "author_image_url"
    }
}

struct Module: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let order: Int
    let days: [Day]
}

struct Day: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let order: Int
    let lessons: [Lesson]
}
