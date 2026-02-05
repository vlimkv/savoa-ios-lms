//
//  ResetPasswordView.swift
//  SAVOA
//
//  Created by 7Я on 06.01.2026.
//

import SwiftUI
import Combine

@MainActor
final class ResetPasswordViewModel: ObservableObject {
    @Published var token: String
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var success: Bool = false

    init(token: String) {
        self.token = token
    }

    func submit() async {
        errorMessage = nil

        let p1 = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let p2 = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        if p1.count < 6 {
            errorMessage = "Пароль должен содержать минимум 6 символов"
            return
        }
        if p1 != p2 {
            errorMessage = "Пароли не совпадают"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // прямой вызов через сеть
            let _ : OkResponse = try await RealNetworkService.shared.request(
                endpoint: APIEndpoints.resetPassword,
                method: "POST",
                body: ["token": token, "new_password": p1],
                headers: ["Authorization": ""] // публичный роут
            )
            success = true
        } catch {
            errorMessage = "Не удалось изменить пароль"
        }
    }
}

struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: ResetPasswordViewModel

    init(token: String) {
        _vm = StateObject(wrappedValue: ResetPasswordViewModel(token: token))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 18) {
                    if vm.success {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 72, weight: .regular))
                                .foregroundColor(.white)
                                .padding(.top, 60)

                            Text("Пароль обновлён")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.white)

                            Text("Теперь войдите с новым паролем.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }

                        Spacer()

                        Button {
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
                        VStack(spacing: 12) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 40, weight: .regular))
                                .foregroundColor(.white)
                                .padding(.top, 60)

                            Text("Новый пароль")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.white)

                            Text("Придумайте новый пароль и подтвердите его.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }

                        VStack(spacing: 14) {
                            MinimalTextField(
                                icon: "lock.fill",
                                placeholder: "Новый пароль",
                                text: $vm.newPassword,
                                isSecure: true
                            )

                            MinimalTextField(
                                icon: "lock.fill",
                                placeholder: "Повторите пароль",
                                text: $vm.confirmPassword,
                                isSecure: true
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 18)

                        if let msg = vm.errorMessage {
                            Text(msg)
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.9))
                                .padding(.horizontal, 24)
                                .multilineTextAlignment(.center)
                        }

                        Spacer()

                        Button {
                            Task { await vm.submit() }
                        } label: {
                            HStack {
                                if vm.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Text("Сохранить пароль")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(26)
                        }
                        .disabled(vm.isLoading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
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
