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
    @State private var message: String?
    @State private var isError = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Reset Password")
                    .font(.title2)
                    .bold()

                TextField("Email", text: $email)
                    .textInputAutocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled(true)
                    .textFieldStyle(.roundedBorder)

                if let message {
                    Text(message)
                        .foregroundColor(isError ? .red : .green)
                        .font(.footnote)
                }

                Button("Send reset link") {
                    sendReset()
                }
                .buttonStyle(.borderedProminent)
                .disabled(email.isEmpty)

                Spacer()
            }
            .padding()
            .navigationTitle("Forgot Password")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func sendReset() {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error {
                message = error.localizedDescription
                isError = true
            } else {
                message = "Password reset email sent."
                isError = false
            }
        }
    }
}
