//
//  ProfileBusiness.swift
//  lastminute
//
//  Created by Jabran Ali on 22/06/2025.
//

import SwiftUI
import Firebase
import PhotosUI

struct bizProfileView: View {
    @Binding var profileImage: Image?
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var jobStore: JobStore
    @Environment(\.dismiss) private var dismiss

    @State private var Name = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var address = ""
    @State private var currentPlan = ""
    @State private var isEditing = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var isLoading = true
    @State private var showSaveAlert = false
    @State private var showChangePassword = false

    private let accentBlue = Color(red: 0.2, green: 0.4, blue: 0.8)

    var body: some View {
        ZStack {
            Color(red: 0.92, green: 0.95, blue: 1.0)
                .ignoresSafeArea()

            if isLoading {
                ProgressView("Loading profile...")
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(12)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile picture
                        profilePictureSection

                        // Business details
                        businessDetailsSection

                        // Current plan
                        planSection

                        // Security section
                        securitySection

                        // Save button (only in edit mode)
                        if isEditing {
                            Button {
                                saveProfile()
                                isEditing = false
                                showSaveAlert = true
                            } label: {
                                Text("Save Changes")
                                    .font(.headline)
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(accentBlue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Business Profile")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
            }

            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(accentBlue)
                }
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if isEditing {
                    Button("Cancel") {
                        isEditing = false
                        loadProfileIfPossible()
                    }
                    .foregroundColor(.red)
                } else {
                    Button("Edit") {
                        isEditing = true
                    }
                    .foregroundColor(accentBlue)
                    .bold()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { loadProfileIfPossible() }
        .onChange(of: authViewModel.user?.uid) { _ in loadProfileIfPossible() }
        .alert("Profile Saved", isPresented: $showSaveAlert) {
            Button("Ok", role: .cancel) { }
        } message: {
            Text("Your profile has been updated successfully.")
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView()
        }
    }

    // MARK: - Security Section

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Security")
                .font(.headline)
                .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))

            Button {
                showChangePassword = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(accentBlue)
                        .frame(width: 24)
                    Text("Change Password")
                        .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                .cornerRadius(10)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(14)
    }

    // MARK: - Profile Picture Section

    private var profilePictureSection: some View {
        VStack(spacing: 12) {
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                ZStack {
                    if let profileImage = profileImage {
                        profileImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(accentBlue.opacity(0.1))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(accentBlue)
                            )
                    }

                    if isEditing {
                        Circle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            )
                    }
                }
            }
            .disabled(!isEditing)
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        profileImage = Image(uiImage: uiImage)
                    }
                }
            }

            if isEditing {
                Text("Tap to change photo")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(14)
    }

    // MARK: - Business Details Section

    private var businessDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Business Details")
                .font(.headline)
                .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
                .padding(.bottom, 4)

            profileField(icon: "building.2.fill", placeholder: "Business Name", text: $Name)
            profileField(icon: "envelope.fill", placeholder: "Email", text: $email, keyboard: .emailAddress)
            profileField(icon: "phone.fill", placeholder: "Phone Number", text: $phoneNumber, keyboard: .phonePad)
            profileField(icon: "mappin.circle.fill", placeholder: "Address", text: $address)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(14)
    }

    // MARK: - Plan Section

    private var planSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Plan")
                .font(.headline)
                .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))

            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(accentBlue)
                Text(currentPlan.isEmpty ? "Pay As You Go" : currentPlan.uppercased())
                    .font(.subheadline.bold())
                    .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
                Spacer()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
    }

    // MARK: - Profile Field Helper

    private func profileField(icon: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(accentBlue)
                .frame(width: 24, alignment: .center)

            if isEditing {
                TextField("", text: text, prompt: Text(placeholder).foregroundColor(.gray.opacity(0.7)))
                    .foregroundColor(.black)
                    .keyboardType(keyboard)
            } else {
                Text(text.wrappedValue.isEmpty ? placeholder : text.wrappedValue)
                    .foregroundColor(text.wrappedValue.isEmpty ? .gray.opacity(0.7) : .black)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.96, green: 0.97, blue: 0.98))
        .cornerRadius(10)
    }

    // MARK: - Ensure safe loading
    private func loadProfileIfPossible() {
        guard authViewModel.user?.uid != nil else {
            isLoading = false
            return
        }
        loadProfile()
    }

    // MARK: - Load business profile
    private func loadProfile() {
        guard let uid = authViewModel.user?.uid else {
            isLoading = false
            return
        }

        isLoading = true
        let db = Firestore.firestore()

        db.collection("users").document(uid).getDocument { snapshot, error in
            defer { isLoading = false }

            if let error = error {
                print("Error loading profile: \(error)")
                return
            }

            guard let data = snapshot?.data() else {
                print("No document found for uid \(uid)")
                return
            }

            Name = data["name"] as? String ?? ""
            email = data["email"] as? String ?? ""
            phoneNumber = data["phoneNumber"] as? String ?? ""
            address = data["address"] as? String ?? ""
            currentPlan = data["plan"] as? String ?? "payg"
        }
    }

    // MARK: - Save business profile
    private func saveProfile() {
        guard let uid = authViewModel.user?.uid else { return }
        let db = Firestore.firestore()

        let profileData: [String: Any] = [
            "name": Name,
            "email": email,
            "phoneNumber": phoneNumber,
            "address": address,
            "postCode": "",
            "plan": currentPlan,
            "role": "business"
        ]

        db.collection("users").document(uid).setData(profileData) { error in
            if let error = error {
                print("Error saving business profile: \(error)")
            }
        }
    }
}
