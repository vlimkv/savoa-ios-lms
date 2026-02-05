//
//  AppState.swift
//  PelvicFloorApp
//
//  Created by 7Я on 04.12.2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    
    private let authService: AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.authService = AuthService.shared
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        isAuthenticated = authService.isAuthenticated()
        currentUser = authService.getCurrentUser()
    }
    
    func logout() {
        authService.logout()
        isAuthenticated = false
        currentUser = nil
    }
}
