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
    
    // ✅ New fields for worker characteristics
    let allSkills = ["Cashier", "Delivery Driver", "Stock Replenisher", "Waiter", "Cook/Chef"]
    @State private var selectedSkills: Set<String> = []
    @State private var hasDrivingLicense = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // ✅ Full white screen
                Color.white.ignoresSafeArea()
                
                Form {
                    Section(
                        header:
                            HStack {
                                Text("Profile Picture")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.black)
                                    .textCase(nil)
                                Spacer()
                            }
                    ) {
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
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
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
                    }
                    
                    Section(
                        header:
                            HStack {
                                Text("Personal Details")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.black)
                                    .textCase(nil)
                                Spacer()
                            }
                    ) {
                        TextField("First Name", text: $firstName).disabled(!isEditing)
                        TextField("Last Name", text: $lastName).disabled(!isEditing)
                        TextField("Email", text: $email).disabled(!isEditing)
                        TextField("Mobile Phone Number", text: $mobilePhoneNumber).disabled(!isEditing)
                        TextField("Address", text: $address).disabled(!isEditing)
                        TextField("Experience", text: $experience).disabled(!isEditing)
                    }
                    
                    Section(
                        header:
                            HStack {
                                Text("Worker Characteristics")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.black)
                                    .textCase(nil)
                                Spacer()
                            }
                    ) {
                        VStack(alignment: .leading) {
                            Text("Skills")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            ForEach(allSkills, id: \.self) { skill in
                                ProfileMultipleSelectionRow(
                                    title: skill,
                                    isSelected: selectedSkills.contains(skill)
                                ) {
                                    if selectedSkills.contains(skill) {
                                        selectedSkills.remove(skill)
                                    } else {
                                        selectedSkills.insert(skill)
                                    }
                                }
                            }
                        }
                        
                        Toggle("Has Driving License", isOn: $hasDrivingLicense)
                    }
                }
                // ✅ removes grey grouped background
                .scrollContentBackground(.hidden)
                .background(Color.white)
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        authViewModel.currentScreen = .workerDashboard
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Dashboard")
                        }
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            saveProfile()
                            isEditing = false
                        }
                        Button("Cancel") {
                            isEditing = false
                            loadProfile()
                        }
                    } else {
                        Button("Edit") {
                            isEditing = true
                        }
                    }
                }
            }
            .onAppear {
                loadProfile()
            }
        }
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

// ✅ Helper view for multi-select skills
struct ProfileMultipleSelectionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
        .padding(.vertical, 4)
    }
}

