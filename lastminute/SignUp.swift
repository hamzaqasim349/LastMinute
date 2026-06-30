//
//  SignUp.swift
//  lastminute
//
//  Created by Jabran Ali on 20/06/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var jobStore: JobStore
    @Binding var path: NavigationPath
    let role: UserRole  // Passed in when creating the view

    // Form fields
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var address = ""
    @State private var postCode = ""
    @State private var country = ""
    @State private var mobileNumber = ""
    @State private var email = ""
    @State private var password = ""

    // ✅ New fields for worker characteristics
    let allSkills = ["Cashier", "Delivery Driver", "Stock Replenisher", "Waiter", "Cook/Chef"]
    @State private var selectedSkills: Set<String> = []
    @State private var hasDrivingLicense = false
    
    // New Field for Business Charecteristics
    @State private var requiredSkills: Set<String> = []
    @State private var requiresDrivingLicense = false

    @State private var errorMessage: String?
    @State private var isLoading = false

    var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !address.isEmpty &&
        !postCode.isEmpty &&
        !country.isEmpty &&
        !mobileNumber.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("\(role == .worker ? "Worker" : "Business") Sign Up")
                    .font(.largeTitle)
                    .bold()

                Group {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Address", text: $address)
                    TextField("Post Code", text: $postCode)
                    TextField("Country", text: $country)
                    TextField("Mobile Number", text: $mobileNumber)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())

                // ✅ Worker-specific fields
                if role == .worker {
                    Section(header: Text("Worker Details")) {
                        VStack(alignment: .leading) {
                            Text("Skills").font(.subheadline).foregroundColor(.gray)
                            ForEach(allSkills, id: \.self) { skill in
                                SignUpMultipleSelectionRow(title: skill, isSelected: selectedSkills.contains(skill)) {
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
                // ✅ Business-specific fields
                if role == .business {
                    Section(header: Text("What are you looking for?")) {
                        VStack(alignment: .leading) {
                            Text("Required Skills")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            ForEach(allSkills, id: \.self) { skill in
                                SignUpMultipleSelectionRow(
                                    title: skill,
                                    isSelected: requiredSkills.contains(skill)
                                ) {
                                    if requiredSkills.contains(skill) {
                                        requiredSkills.remove(skill)
                                    } else {
                                        requiredSkills.insert(skill)
                                    }
                                }
                            }
                        }

                        Toggle("Requires Driving License", isOn: $requiresDrivingLicense)
                    }
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                
                

                Button {
                    hideKeyboard()
                    signUp()
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Create Account")
                            .bold()
                    }
                }
                .disabled(!isFormValid || isLoading)
                .padding()
                .frame(maxWidth: .infinity)
                .background(isFormValid ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)

                Spacer()
            }
            .padding()
        }
    }

    private func signUp() {
        isLoading = true
        errorMessage = nil

        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        let trimmedPassword = password.trimmingCharacters(in: .whitespaces)

        Auth.auth().createUser(withEmail: trimmedEmail, password: trimmedPassword) { result, error in
            DispatchQueue.main.async { self.isLoading = false }

            if let error = error {
                DispatchQueue.main.async { self.errorMessage = "Signup failed: \(error.localizedDescription)" }
                return
            }

            guard let uid = result?.user.uid else {
                DispatchQueue.main.async { self.errorMessage = "Unable to get user ID" }
                return
            }

            let db = Firestore.firestore()
           var userData: [String: Any] = [
                "firstName": firstName,
                "lastName": lastName,
                "address": address,
                "postCode": postCode,
                "country": country,
                "mobileNumber": mobileNumber,
                "email": trimmedEmail,
                "role": role.rawValue
            ]

            // ✅ Include worker characteristics if role is worker
            if role == .worker {
                userData["skills"] = Array(selectedSkills)
                userData["hasDrivingLicense"] = hasDrivingLicense
            }
            
            if role == .business {
                userData["requiredSkills"] = Array(requiredSkills)
                userData["requiresDrivingLicense"] = requiresDrivingLicense
            }

            db.collection("users").document(uid).setData(userData) { error in
                if let error = error {
                    DispatchQueue.main.async { self.errorMessage = "Error saving user data: \(error.localizedDescription)" }
                    return
                }

                DispatchQueue.main.async {
                    self.authViewModel.user = result?.user
                    self.authViewModel.userRole = role
                    self.jobStore.startListeners(for: uid, userRole: role.rawValue)

                    if role == .business {
                        self.path.append(SignUpRoute.paymentPlan)
                    } else {
                        self.path.append(SignUpRoute.workerDashboard(userID: uid))
                    }
                }
            }
        }
    }

    private func hideKeyboard() {
#if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
    }
}

// ✅ Helper view for multi-select skills
struct SignUpMultipleSelectionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title).foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark").foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
