//
//  ChangePasswordView.swift
//  lastminute
//
//  Created by Hamza Qasim on 30/06/2026.
//

import SwiftUI
import FirebaseAuth

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    @State private var currentError: String?
    @State private var newError: String?
    @State private var confirmError: String?

    @State private var isLoading = false
    @State private var statusPopup: StatusPopupData? = nil
    @State private var didSucceed = false

    private let accentBlue = Color(red: 0.2, green: 0.4, blue: 0.8)

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.92, green: 0.95, blue: 1.0)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Change Password")
                                .font(.headline)
                                .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
                                .padding(.bottom, 4)

                            secureField(icon: "lock.fill", placeholder: "Current Password", text: $currentPassword, error: currentError)
                            secureField(icon: "lock.rotation", placeholder: "New Password (min 6 characters)", text: $newPassword, error: newError)
                            secureField(icon: "lock.rotation", placeholder: "Confirm New Password", text: $confirmPassword, error: confirmError)
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(14)

                        Button {
                            changePassword()
                        } label: {
                            Text("Update Password")
                                .font(.headline)
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(accentBlue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                }
                .scrollDismissesKeyboard(.interactively)

                if isLoading {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView("Updating...")
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Change Password")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(accentBlue)
                }
            }
            .statusPopup($statusPopup)
            .onChange(of: statusPopup) { newValue in
                // Popup was dismissed after a successful change → close the sheet
                if newValue == nil && didSucceed {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Field Helper

    private func secureField(icon: String, placeholder: String, text: Binding<String>, error: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(accentBlue)
                    .frame(width: 24, alignment: .center)

                SecureField("", text: text, prompt: Text(placeholder).foregroundColor(.gray.opacity(0.7)))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.96, green: 0.97, blue: 0.98))
            .cornerRadius(10)

            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Change Password Logic

    private func changePassword() {
        currentError = nil
        newError = nil
        confirmError = nil

        var hasError = false

        if currentPassword.isEmpty {
            currentError = "Enter your current password"
            hasError = true
        }
        if newPassword.count < 6 {
            newError = "Password must be at least 6 characters"
            hasError = true
        }
        if confirmPassword != newPassword {
            confirmError = "Passwords do not match"
            hasError = true
        }

        guard !hasError else { return }

        guard let user = Auth.auth().currentUser, let email = user.email else {
            showResult(title: "Error", message: "No signed-in user found.", success: false)
            return
        }

        isLoading = true

        // Reauthenticate first (Firebase requires recent login to change password)
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                DispatchQueue.main.async {
                    isLoading = false
                    currentError = "Current password is incorrect"
                    print("Reauth error: \(error.localizedDescription)")
                }
                return
            }

            // Now update the password
            user.updatePassword(to: newPassword) { error in
                DispatchQueue.main.async {
                    isLoading = false
                    if let error = error {
                        showResult(title: "Update Failed", message: error.localizedDescription, success: false)
                    } else {
                        showResult(title: "Success", message: "Your password has been updated successfully.", success: true)
                    }
                }
            }
        }
    }

    private func showResult(title: String, message: String, success: Bool) {
        didSucceed = success
        withAnimation {
            statusPopup = StatusPopupData(kind: success ? .success : .error, title: title, message: message)
        }
    }
}
