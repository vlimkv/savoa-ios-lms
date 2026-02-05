//
//  AuthError..swift
//  SAVOA
//
//  Created by 7Я on 27.12.2025.
//

import Foundation

enum AuthError: LocalizedError {
    case invalidCredentials
    case server(String)
    case connection
    case parsing
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Неверный email или пароль"
        case .server(let msg):
            return msg
        case .connection:
            return "Проблема с подключением к серверу"
        case .parsing:
            return "Сервер вернул неожиданный ответ"
        case .unknown:
            return "Произошла ошибка"
        }
    }
}
