//
//  LoginInView.swift
//  lastminute
//
//  Created by Jabran Ali on 21/06/2025.
//
import SwiftUI

struct LogInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var showForgotPassword = false
    @State private var isLoading = false
    @State private var showErrorAlert = false
    @FocusState private var emailFieldFocused: Bool

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.7, green: 0.85, blue: 1.0), Color(red: 0.85, green: 0.9, blue: 1.0)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                Spacer(minLength: 60)

                // Title
                Text("Welcome Back")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                    .padding(.bottom, 30)

                // Input fields
                VStack(spacing: 4) {
                    // Email field
                    TextField("", text: $email, prompt: Text("Email").foregroundColor(.gray.opacity(0.7)))
                        .padding()
                        .background(Color.white.opacity(0.85))
                        .cornerRadius(12)
                        .foregroundColor(.black)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($emailFieldFocused)
                        .onChange(of: email) { _ in
                            emailError = nil
                        }
                        .onChange(of: emailFieldFocused) { focused in
                            if !focused {
                                validateEmail()
                            }
                        }
                        .onSubmit {
                            validateEmail()
                        }

                    // Email error label
                    if let emailError = emailError {
                        HStack {
                            Text(emailError)
                                .foregroundColor(.red)
                                .font(.caption)
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 2)
                    }

                    // Password field
                    SecureField("", text: $password, prompt: Text("Password").foregroundColor(.gray.opacity(0.7)))
                        .padding()
                        .background(Color.white.opacity(0.85))
                        .cornerRadius(12)
                        .foregroundColor(.black)
                        .padding(.top, 12)
                        .onChange(of: password) { _ in
                            passwordError = nil
                        }

                    // Password error label
                    if let passwordError = passwordError {
                        HStack {
                            Text(passwordError)
                                .foregroundColor(.red)
                                .font(.caption)
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 30)

                Spacer()

                // Bottom buttons
                VStack(spacing: 16) {
                    Button("Forgot password?") {
                        showForgotPassword = true
                    }
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.15, green: 0.3, blue: 0.65))

                    Button {
                        attemptLogin()
                    } label: {
                        Text("Log In")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.2, green: 0.4, blue: 0.8))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(isLoading)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }

            // Loading overlay
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                ProgressView("Signing in...")
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 10)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
        .alert("Login Failed", isPresented: $showErrorAlert) {
            Button("Ok", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }

    // MARK: - Validation & Login

    private func attemptLogin() {
        // Reset errors
        emailError = nil
        passwordError = nil
        errorMessage = nil

        var hasError = false

        // Validate email
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        if trimmedEmail.isEmpty {
            emailError = "Email can't be empty"
            hasError = true
        } else if !isValidEmail(trimmedEmail) {
            emailError = "Please enter a valid email address"
            hasError = true
        }

        // Validate password
        if password.isEmpty {
            passwordError = "Password can't be empty"
            hasError = true
        }

        guard !hasError else { return }

        // Proceed with login
        isLoading = true
        Task {
            do {
                try await authViewModel.signIn(email: trimmedEmail, password: password)
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    private func validateEmail() {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return // Don't show error on empty while just leaving the field
        }
        if !isValidEmail(trimmed) {
            emailError = "Please enter a valid email address"
        }
    }
}
