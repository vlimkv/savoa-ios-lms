//
//  ForgotPasswordView.swift
//  PelvicFloorApp
//
//  Created by 7Я on 04.12.2025.
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 28) {
                    if viewModel.resetEmailSent {
                        // Состояние успеха
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 72, weight: .regular))
                                .foregroundColor(.white)
                                .padding(.top, 60)
                            
                            Text("Письмо отправлено")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.white)
                            
                            Text("Проверьте почту \(viewModel.email) и следуйте инструкции в письме.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        
                        Spacer()
                        
                        Button {
                            viewModel.resetEmailSent = false
                            dismiss()
                        } label: {
                            Text("Готово")
                                .font(.system(size: 17, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(26)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)
                        
                    } else {
                        // Ввод email
                        VStack(spacing: 18) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 40, weight: .regular))
                                .foregroundColor(.white)
                                .padding(.top, 60)
                            
                            Text("Восстановление пароля")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.white)
                            
                            Text("Введите email, который мы указали при выдаче данных для входа.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        
                        MinimalTextField(
                            icon: "envelope.fill",
                            placeholder: "Email",
                            text: $viewModel.email
                        )
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.9))
                                .padding(.horizontal, 24)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer()
                        
                        Button {
                            Task {
                                await viewModel.requestPasswordReset()
                            }
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(
                                            CircularProgressViewStyle(tint: .black)
                                        )
                                } else {
                                    Text("Отправить письмо")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(26)
                        }
                        .disabled(viewModel.isLoading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.resetEmailSent = false
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    ForgotPasswordView(viewModel: AuthViewModel())
}
