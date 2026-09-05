//
//  Profile.swift
//  lastminute
//
//  Created by Jabran Ali on 21/06/2025.
//
import SwiftUI
import PhotosUI
import Firebase

struct ProfileView: View {
    @Binding var profileImage: Image?
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var jobStore: JobStore

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var experience = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var mobilePhoneNumber = ""
    @State private var address = ""
    @State private var isEditing = false
    @State private var showSaveAlert = false
    @State private var showChangePassword = false

    let allSkills = ["Cashier", "Delivery Driver", "Stock Replenisher", "Waiter", "Cook/Chef"]
    @State private var selectedSkills: Set<String> = []
    @State private var hasDrivingLicense = false

    private let accentBlue = Color(red: 0.2, green: 0.4, blue: 0.8)

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.92, green: 0.95, blue: 1.0)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        profilePictureSection
                        personalDetailsSection
                        characteristicsSection
                        securitySection

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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Profile")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        authViewModel.currentScreen = .workerDashboard
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(accentBlue)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Cancel") {
                            isEditing = false
                            loadProfile()
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
            .onAppear {
                loadProfile()
            }
            .alert("Profile Saved", isPresented: $showSaveAlert) {
                Button("Ok", role: .cancel) { }
            } message: {
                Text("Your profile has been updated successfully.")
            }
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordView()
            }
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
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
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
            .onChange(of: selectedItem) { newItem, _ in
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

    // MARK: - Personal Details Section

    private var personalDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personal Details")
                .font(.headline)
                .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
                .padding(.bottom, 4)

            profileField(icon: "person.fill", placeholder: "First Name", text: $firstName)
            profileField(icon: "person.fill", placeholder: "Last Name", text: $lastName)
            profileField(icon: "envelope.fill", placeholder: "Email", text: $email, keyboard: .emailAddress)
            profileField(icon: "phone.fill", placeholder: "Mobile Phone Number", text: $mobilePhoneNumber, keyboard: .phonePad)
            profileField(icon: "mappin.circle.fill", placeholder: "Address", text: $address)
            profileField(icon: "briefcase.fill", placeholder: "Experience", text: $experience)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(14)
    }

    // MARK: - Characteristics Section

    private var characteristicsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Worker Characteristics")
                .font(.headline)
                .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))

            Text("Skills")
                .font(.subheadline)
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                ForEach(allSkills, id: \.self) { skill in
                    Button {
                        guard isEditing else { return }
                        if selectedSkills.contains(skill) {
                            selectedSkills.remove(skill)
                        } else {
                            selectedSkills.insert(skill)
                        }
                    } label: {
                        HStack {
                            Text(skill)
                                .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
                            Spacer()
                            if selectedSkills.contains(skill) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(accentBlue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .disabled(!isEditing)
                }
            }
            .padding()
            .background(Color(red: 0.96, green: 0.97, blue: 0.98))
            .cornerRadius(10)

            Toggle("Has Driving License", isOn: $hasDrivingLicense)
                .disabled(!isEditing)
                .padding()
                .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                .cornerRadius(10)
                .tint(accentBlue)
        }
        .padding(20)
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

    // MARK: - Load profile from Firestore
    private func loadProfile() {
        guard let uid = authViewModel.user?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data(), error == nil {
                firstName = data["firstName"] as? String ?? ""
                lastName = data["lastName"] as? String ?? ""
                email = data["email"] as? String ?? ""
                mobilePhoneNumber = data["mobilePhoneNumber"] as? String ?? ""
                address = data["address"] as? String ?? ""
                experience = data["experience"] as? String ?? ""
                selectedSkills = Set(data["skills"] as? [String] ?? [])
                hasDrivingLicense = data["hasDrivingLicense"] as? Bool ?? false
            }
        }
    }

    // MARK: - Save profile to Firestore
    private func saveProfile() {
        guard let uid = authViewModel.user?.uid else { return }

        let db = Firestore.firestore()
        let profileData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "mobilePhoneNumber": mobilePhoneNumber,
            "address": address,
            "experience": experience,
            "skills": Array(selectedSkills),
            "hasDrivingLicense": hasDrivingLicense
        ]

        db.collection("users").document(uid).setData(profileData, merge: true) { error in
            if let error = error {
                print("Error saving profile: \(error)")
            } else {
                print("Profile saved successfully")
            }
        }
    }
}
