//
//  LoginView.swift
//  PelvicFloorApp
//
//  Created by 7Я on 04.12.2025.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    @State private var logoScale: CGFloat = 0.9
    @State private var contentOpacity: Double = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Чистый тёмный фон
                Color.black
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Логотип
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .padding(.top, 80)
                            .scaleEffect(logoScale)
                        
                        // Заголовок и подзаголовок (без упоминаний курса)
                        VStack(spacing: 8) {
                            Text("Вход в аккаунт")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Введите логин или email и пароль.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .opacity(contentOpacity)
                        
                        // Поля ввода
                        VStack(spacing: 14) {
                            MinimalTextField(
                                icon: "person.fill",
                                placeholder: "Логин или email",
                                text: $viewModel.email
                            )
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            
                            MinimalTextField(
                                icon: "lock.fill",
                                placeholder: "Пароль",
                                text: $viewModel.password,
                                isSecure: true
                            )
                            .textContentType(.password)
                        }
                        .padding(.horizontal, 24)
                        .opacity(contentOpacity)
                        
                        // Ошибка
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.9))
                                .padding(.horizontal, 24)
                                .multilineTextAlignment(.center)
                                .transition(.opacity)
                        }
                        
                        // Забыл пароль
                        Button {
                            viewModel.showForgotPassword = true
                        } label: {
                            Text("Забыли пароль?")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 4)
                        .opacity(contentOpacity)
                        
                        // Кнопка входа
                        Button {
                            Task { await viewModel.login() }
                        } label: {
                            HStack(spacing: 10) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(
                                            CircularProgressViewStyle(tint: .black)
                                        )
                                } else {
                                    Text("Войти")
                                        .font(.system(size: 17, weight: .semibold))
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(28)
                        }
                        .disabled(viewModel.isLoading)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                        .opacity(contentOpacity)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showForgotPassword) {
                ForgotPasswordView(viewModel: viewModel)
            }
            .onAppear {
                // Плавность можно убрать полностью — оставим без анимаций
                logoScale = 1.0
                contentOpacity = 1.0
                
                viewModel.onLoginSuccess = {
                    appState.checkAuthStatus()
                }
            }
        }
    }
}

// MARK: - Минималистичное текстовое поле

struct MinimalTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .autocorrectionDisabled(true)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .autocorrectionDisabled(true)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
}
