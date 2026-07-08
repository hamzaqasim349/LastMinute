//
//  ForgotPassword.swift
//  lastminute
//
//  Created by Jabran Ali on 28/12/2025.
//

import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var emailError: String?
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    @FocusState private var emailFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                // Same gradient as login
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.7, green: 0.85, blue: 1.0), Color(red: 0.85, green: 0.9, blue: 1.0)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Title
                    Text("Reset Password")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(red: 0.15, green: 0.2, blue: 0.4))
                        .padding(.top, 30)

                    Text("Enter your email to receive a reset link")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.5))
                        .padding(.top, 6)
                        .padding(.bottom, 40)

                    // Email field
                    VStack(spacing: 4) {
                        TextField("", text: $email, prompt: Text("Email").foregroundColor(.gray.opacity(0.7)))
                            .padding()
                            .background(Color.white.opacity(0.85))
                            .cornerRadius(12)
                            .foregroundColor(.black)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
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
                    }
                    .padding(.horizontal, 30)

                    // Send button
                    Button {
                        attemptReset()
                    } label: {
                        Text("Send Reset Link")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isEmailValid ? Color(red: 0.2, green: 0.4, blue: 0.8) : Color(red: 0.2, green: 0.4, blue: 0.8).opacity(0.4))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(!isEmailValid || isLoading)
                    .padding(.horizontal, 30)
                    .padding(.top, 24)

                    Spacer()
                }

                // Loading overlay
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    ProgressView("Sending...")
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.15, green: 0.3, blue: 0.65))
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("Ok", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - Validation & Reset

    private var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && isValidEmail(trimmed) && emailError == nil
    }

    private func attemptReset() {
        emailError = nil

        let trimmed = email.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            emailError = "Email can't be empty"
            return
        }
        if !isValidEmail(trimmed) {
            emailError = "Please enter a valid email address"
            return
        }

        isLoading = true
        Auth.auth().sendPasswordReset(withEmail: trimmed) { error in
            isLoading = false
            if let error {
                alertTitle = "Error"
                alertMessage = error.localizedDescription
            } else {
                alertTitle = "Email Sent"
                alertMessage = "A password reset link has been sent to your email."
            }
            showAlert = true
        }
    }

    private func validateEmail() {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return }
        if !isValidEmail(trimmed) {
            emailError = "Please enter a valid email address"
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}
