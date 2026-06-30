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
    @State private var showForgotPassword = false

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
                VStack(spacing: 16) {
                    TextField("", text: $email, prompt: Text("Email").foregroundColor(.gray.opacity(0.7)))
                        .padding()
                        .background(Color.white.opacity(0.85))
                        .cornerRadius(12)
                        .foregroundColor(.black)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    SecureField("", text: $password, prompt: Text("Password").foregroundColor(.gray.opacity(0.7)))
                        .padding()
                        .background(Color.white.opacity(0.85))
                        .cornerRadius(12)
                        .foregroundColor(.black)

                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
                .padding(.horizontal, 30)

                Spacer()

                // Bottom buttons
                VStack(spacing: 16) {
                    Button("Forgot password?") {
                        showForgotPassword = true
                    }
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.85))

                    Button {
                        Task {
                            do {
                                try await authViewModel.signIn(email: email, password: password)
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        Text(authViewModel.isLoading ? "Loading..." : "Log In")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.2, green: 0.4, blue: 0.8))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(authViewModel.isLoading)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }
}
