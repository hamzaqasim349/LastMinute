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

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading profile…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Form {
                    Section(header: Text("Profile Picture")
                        .foregroundColor(.black)) {
                        PhotosPicker(
                            selection: $selectedItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            if let profileImage = profileImage {
                                profileImage
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "building.2.crop.circle")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                            }
                        }
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    profileImage = Image(uiImage: uiImage)
                                }
                            }
                        }
                        .disabled(!isEditing)
                    }

                    Section(header: Text("Business Details")
                        .foregroundColor(.black)) {
                        TextField("Business Name", text: $Name).disabled(!isEditing)
                        TextField("Email", text: $email).disabled(!isEditing)
                        TextField("Phone Number", text: $phoneNumber).disabled(!isEditing)
                        TextField("Address", text: $address).disabled(!isEditing)
                    }

                    Section(header: Text("Current Plan")
                        .foregroundColor(.black)) {
                        Text(currentPlan).foregroundColor(.black)
                    }
                }
                .scrollContentBackground(.hidden) // 🔑 removes grouped background
                .background(Color.white)          // 🔑 forces white form background
            }
        }
        .background(Color.white.ignoresSafeArea()) // 🔑 whole screen white
        .navigationTitle("Business Profile")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Dashboard")
                    }
                }
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if isEditing {
                    Button("Save") { saveProfile(); isEditing = false }
                    Button("Cancel") { isEditing = false; loadProfileIfPossible() }
                } else {
                    Button("Edit") { isEditing = true }
                }
            }
        }
        .onAppear { loadProfileIfPossible() }
        .onChange(of: authViewModel.user?.uid) { _ in loadProfileIfPossible() }
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
            } else {
                print("Business profile saved successfully")
            }
        }
    }
}
