//
//  AuthViewModel.swift
//  PelvicFloorApp
//
//  Created by 7Я on 04.12.2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showForgotPassword: Bool = false
    @Published var resetEmailSent: Bool = false
    
    private let authService: AuthServiceProtocol
    var onLoginSuccess: (() -> Void)?
    
    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }
    
    // Convenience init with default service
    convenience init() {
        self.init(authService: AuthService.shared)
    }
    
    // MARK: - Login
    
    func login() async {
        guard validateLoginInput() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await authService.login(email: email, password: password)
            onLoginSuccess?()
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Произошла ошибка"
        }
        
        isLoading = false
    }
    
    private func validateLoginInput() -> Bool {
        errorMessage = nil

        let login = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let pass  = password.trimmingCharacters(in: .whitespacesAndNewlines)

        if login.isEmpty || pass.isEmpty {
            errorMessage = "Заполните все поля"
            return false
        }

        if login.count < 3 {
            errorMessage = "Введите логин или email"
            return false
        }

        if pass.count < 6 {
            errorMessage = "Пароль должен содержать минимум 6 символов"
            return false
        }

        return true
    }
    
    // MARK: - Forgot Password
    
    func requestPasswordReset() async {
        guard !email.isEmpty else {
            errorMessage = "Введите email"
            return
        }
        
        guard email.isValidEmail() else {
            errorMessage = "Введите корректный email"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.requestPasswordReset(email: email)
            errorMessage = nil
            resetEmailSent = true
        } catch {
            errorMessage = "Не удалось отправить письмо"
        }
        
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
    }
}
