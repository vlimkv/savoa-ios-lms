//
//  CourseService.swift
//  PelvicFloorApp
//

import Foundation

protocol CourseServiceProtocol {
    func fetchCourse() async throws -> Course
}

final class CourseService: CourseServiceProtocol {
    static let shared = CourseService()
    
    private var cachedCourse: Course?
    private let apiClient: APIClient
    private let storage: StorageServiceProtocol
    
    init(
        apiClient: APIClient = .shared,
        storage: StorageServiceProtocol = StorageService.shared
    ) {
        self.apiClient = apiClient
        self.storage = storage
    }
    
    func fetchCourse() async throws -> Course {
        if let cachedCourse {
            return cachedCourse
        }
        
        let course = try await fetchFromAPI()
        cachedCourse = course
        return course
    }
    
    private func fetchFromAPI() async throws -> Course {
        // Backend response structure
        struct WeekResponse: Codable {
            let id: String
            let title: String?
            let description: String?
            let image_id: String?
            let order_index: Int
            let lessons: [LessonResponse]
        }
        
        struct LessonResponse: Codable {
            let id: String
            let title: String
            let description: String?
            let day_order: Int
            let duration: Int
            let week_id: String
            let image_id: String?
            let thumbnail_url: String?

            let is_locked: Bool?
            let unlock_date: String?
        }
        
        guard let token = storage.loadFromKeychain(forKey: StorageService.Keys.authToken) else {
            throw CourseError.unauthorized
        }
        
        let weeks: [WeekResponse] = try await apiClient.request(
            "/course/weeks",
            method: "GET",
            token: token
        )
        
        print("📦 Loaded \(weeks.count) weeks from API")
        
        var modules: [Module] = []
        
        for week in weeks.sorted(by: { $0.order_index < $1.order_index }) {
            print("📅 Week \(week.order_index): '\(week.title ?? "no title")', lessons count: \(week.lessons.count)")
            
            // Группируем уроки по day_order
            let lessonsByDay = Dictionary(grouping: week.lessons) { $0.day_order }
            
            var days: [Day] = []
            
            // Сортируем дни и создаем Day структуры
            for (dayOrder, dayLessons) in lessonsByDay.sorted(by: { $0.key < $1.key }) {
                
                // Конвертируем LessonResponse -> Lesson
                let lessons = dayLessons.map { lessonResp in
                    Lesson(
                        id: lessonResp.id,
                        title: lessonResp.title,
                        description: lessonResp.description ?? "",
                        type: .video,
                        duration: lessonResp.duration,
                        videoURL: nil,
                        thumbnailURL: lessonResp.thumbnail_url,
                        notes: nil,
                        order: lessonResp.day_order,
                        isLocked: lessonResp.is_locked,
                        unlockDate: lessonResp.unlock_date
                    )
                }
                
                print("  📌 Day \(dayOrder): \(lessons.count) lessons")
                for lesson in lessons {
                    print("    ▶️ \(lesson.title) (\(lesson.duration)s)")
                }
                
                let day = Day(
                    id: "day_\(week.id)_\(dayOrder)",
                    title: "День \(dayOrder)",
                    description: "",
                    order: dayOrder,
                    lessons: lessons
                )
                
                days.append(day)
            }
            
            let module = Module(
                id: week.id,
                title: week.title ?? "Неделя \(week.order_index)",
                description: week.description ?? "",
                order: week.order_index,
                days: days
            )
            
            modules.append(module)
            
            print("  ✅ Module created: \(module.days.count) days, \(module.days.flatMap { $0.lessons }.count) total lessons")
        }
        
        print("✅ Course built: \(modules.count) modules")
        
        return Course(
            id: "main",
            title: "RE:STORE",
            description: "Программа восстановления тазового дна",
            modules: modules,
            authorName: "Seza Amankeldi",
            authorBio: "",
            authorImageURL: nil
        )
    }
    
    private func imageURL(for imageId: String) -> String {
        return "\(APIEndpoints.baseURL)/images/\(imageId)"
    }
    
    func clearCache() {
        cachedCourse = nil
    }
}

// MARK: - Errors

enum CourseError: Error {
    case unauthorized
    case noData
    case parsing
    
    var localizedDescription: String {
        switch self {
        case .unauthorized: return "Требуется авторизация"
        case .noData: return "Нет данных"
        case .parsing: return "Ошибка парсинга"
        }
    }
}
