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
    let role: UserRole

    // Form fields
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var address = ""
    @State private var postCode = ""
    @State private var country = ""
    @State private var mobileNumber = ""
    @State private var email = ""
    @State private var password = ""

    // Worker fields
    let allSkills = ["Cashier", "Delivery Driver", "Stock Replenisher", "Waiter", "Cook/Chef"]

    let countryList: [String] = {
        Locale.isoRegionCodes.compactMap { code in
            Locale.current.localizedString(forRegionCode: code)
        }.sorted()
    }()
    @State private var selectedSkills: Set<String> = []
    @State private var hasDrivingLicense = false

    // Business fields
    @State private var requiredSkills: Set<String> = []
    @State private var requiresDrivingLicense = false

    // State
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var isLoading = false
    @State private var statusPopup: StatusPopupData? = nil
    @State private var showCountryPicker = false
    @State private var countrySearch = ""
    @FocusState private var emailFieldFocused: Bool

    var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !address.isEmpty &&
        !postCode.isEmpty &&
        !country.isEmpty &&
        !mobileNumber.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        isValidEmail(email.trimmingCharacters(in: .whitespaces)) &&
        password.count >= 6
    }

    var filteredCountries: [String] {
        if countrySearch.isEmpty {
            return countryList
        }
        return countryList.filter { $0.localizedCaseInsensitiveContains(countrySearch) }
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.7, green: 0.85, blue: 1.0), Color(red: 0.85, green: 0.9, blue: 1.0)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Form fields
                        VStack(spacing: 14) {
                            styledTextField("First Name", text: $firstName)
                        styledTextField("Last Name", text: $lastName)
                        styledTextField("Address", text: $address)
                        styledTextField("Post Code", text: $postCode)

                        // Country picker
                        VStack(spacing: 0) {
                            Button {
                                withAnimation {
                                    showCountryPicker.toggle()
                                }
                            } label: {
                                HStack {
                                    Text(country.isEmpty ? "Country" : country)
                                        .foregroundColor(country.isEmpty ? .gray.opacity(0.7) : .black)
                                    Spacer()
                                    Image(systemName: showCountryPicker ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.gray.opacity(0.7))
                                }
                                .padding()
                                .background(Color.white.opacity(0.85))
                                .cornerRadius(12)
                            }

                            if showCountryPicker {
                                VStack(spacing: 0) {
                                    // Search bar
                                    TextField("", text: $countrySearch, prompt: Text("Search country").foregroundColor(.gray.opacity(0.7)))
                                        .padding(10)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 8)
                                        .padding(.top, 8)

                                    ScrollView {
                                        VStack(spacing: 0) {
                                            ForEach(filteredCountries, id: \.self) { c in
                                                Button {
                                                    country = c
                                                    countrySearch = ""
                                                    withAnimation {
                                                        showCountryPicker = false
                                                    }
                                                } label: {
                                                    HStack {
                                                        Text(c)
                                                            .foregroundColor(.black)
                                                        Spacer()
                                                        if c == country {
                                                            Image(systemName: "checkmark")
                                                                .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.8))
                                                        }
                                                    }
                                                    .padding(.horizontal)
                                                    .padding(.vertical, 10)
                                                }
                                                Divider()
                                            }
                                        }
                                    }
                                }
                                .frame(maxHeight: 200)
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(12)
                                .padding(.top, 4)
                            }
                        }

                        styledTextField("Mobile Number", text: $mobileNumber, keyboard: .phonePad)

                        // Email with validation
                        VStack(spacing: 4) {
                            TextField("", text: $email, prompt: Text("Email").foregroundColor(.gray.opacity(0.7)))
                                .padding()
                                .background(Color.white.opacity(0.85))
                                .cornerRadius(12)
                                .foregroundColor(.black)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .focused($emailFieldFocused)
                                .onChange(of: email) { _ in emailError = nil }
                                .onChange(of: emailFieldFocused) { focused in
                                    if !focused { validateEmail() }
                                }
                                .onSubmit { validateEmail() }

                            if let emailError = emailError {
                                HStack {
                                    Text(emailError)
                                        .foregroundColor(.red)
                                        .font(.caption)
                                    Spacer()
                                }
                                .padding(.horizontal, 4)
                            }
                        }

                        // Password with validation
                        VStack(spacing: 4) {
                            SecureField("", text: $password, prompt: Text("Password (min 6 characters)").foregroundColor(.gray.opacity(0.7)))
                                .padding()
                                .background(Color.white.opacity(0.85))
                                .cornerRadius(12)
                                .foregroundColor(.black)
                                .onChange(of: password) { _ in passwordError = nil }

                            if let passwordError = passwordError {
                                HStack {
                                    Text(passwordError)
                                        .foregroundColor(.red)
                                        .font(.caption)
                                    Spacer()
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                    }
                    .padding(.horizontal, 28)

                    // Role-specific sections
                    if role == .worker {
                        workerDetailsSection
                    }

                    if role == .business {
                        businessDetailsSection
                    }

                    // Create Account button
                    Button {
                        hideKeyboard()
                        signUp()
                    } label: {
                        Text("Create Account")
                            .font(.headline)
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color(red: 0.2, green: 0.4, blue: 0.8) : Color(red: 0.2, green: 0.4, blue: 0.8).opacity(0.4))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isLoading)
                    .padding(.horizontal, 28)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .contentMargins(.top, 24)
            .scrollDismissesKeyboard(.interactively)
            }

            // Loading overlay
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                ProgressView("Creating account...")
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 10)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("\(role == .worker ? "Worker" : "Business") Sign Up")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
            }
        }
        .statusPopup($statusPopup)
    }

    // MARK: - Worker Details Section

    private var workerDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Skills")
                .font(.headline)
                .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))

            VStack(spacing: 8) {
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
            .padding()
            .background(Color.white.opacity(0.85))
            .cornerRadius(12)

            Toggle("Has Driving License", isOn: $hasDrivingLicense)
                .padding()
                .background(Color.white.opacity(0.85))
                .cornerRadius(12)
                .tint(Color(red: 0.2, green: 0.4, blue: 0.8))
        }
        .padding(.horizontal, 28)
        .padding(.top, 20)
    }

    // MARK: - Business Details Section

    private var businessDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What are you looking for?")
                .font(.headline)
                .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))

            VStack(spacing: 8) {
                ForEach(allSkills, id: \.self) { skill in
                    SignUpMultipleSelectionRow(title: skill, isSelected: requiredSkills.contains(skill)) {
                        if requiredSkills.contains(skill) {
                            requiredSkills.remove(skill)
                        } else {
                            requiredSkills.insert(skill)
                        }
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.85))
            .cornerRadius(12)

            Toggle("Requires Driving License", isOn: $requiresDrivingLicense)
                .padding()
                .background(Color.white.opacity(0.85))
                .cornerRadius(12)
                .tint(Color(red: 0.2, green: 0.4, blue: 0.8))
        }
        .padding(.horizontal, 28)
        .padding(.top, 20)
    }

    // MARK: - Styled TextField Helper

    private func styledTextField(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        TextField("", text: text, prompt: Text(placeholder).foregroundColor(.gray.opacity(0.7)))
            .padding()
            .background(Color.white.opacity(0.85))
            .cornerRadius(12)
            .foregroundColor(.black)
            .keyboardType(keyboard)
    }

    // MARK: - Validation

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

    // MARK: - Sign Up

    private func signUp() {
        isLoading = true

        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        let trimmedPassword = password.trimmingCharacters(in: .whitespaces)

        Auth.auth().createUser(withEmail: trimmedEmail, password: trimmedPassword) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    withAnimation {
                        self.statusPopup = StatusPopupData(kind: .error, title: "Sign Up Failed", message: error.localizedDescription)
                    }
                }
                return
            }

            guard let uid = result?.user.uid else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    withAnimation {
                        self.statusPopup = StatusPopupData(kind: .error, title: "Sign Up Failed", message: "Unable to get user ID")
                    }
                }
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
                    DispatchQueue.main.async {
                        self.isLoading = false
                        withAnimation {
                            self.statusPopup = StatusPopupData(kind: .error, title: "Sign Up Failed", message: error.localizedDescription)
                        }
                    }
                    return
                }

                DispatchQueue.main.async {
                    self.isLoading = false
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

// MARK: - Multi-select Row

struct SignUpMultipleSelectionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.8))
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
        }
        .padding(.vertical, 4)
    }
}
