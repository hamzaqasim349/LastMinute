//
//  bPostNewJobForm.swift
//  lastminute
//
//  Created by Jabran Ali on 22/06/2025.
//

import SwiftUI
import FirebaseFirestore

struct bPostNewJobForm: View {
    @State private var jobTitle = ""
    @State private var location = ""
    @State private var pay = ""
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()

    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var path: NavigationPath

    @State private var isPosting = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    let allSkills = ["Cashier", "Delivery Driver", "Stock Replenisher", "Waiter", "Cook/Chef"]
    @State private var selectedSkills: Set<String> = []
    @State private var requiresDrivingLicense = false

    private let accentBlue = Color(red: 0.2, green: 0.4, blue: 0.8)

    var formIsValid: Bool {
        !jobTitle.isEmpty && !location.isEmpty && !pay.isEmpty && !selectedSkills.isEmpty
    }

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.92, green: 0.95, blue: 1.0)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // Job Info Section
                    VStack(alignment: .leading, spacing: 14) {
                        sectionHeader("Job Info")

                        styledField("Job Title", text: $jobTitle)
                        styledField("Address", text: $location)

                        // Pay field with currency
                        HStack(spacing: 0) {
                            TextField("", text: $pay, prompt: Text("Pay").foregroundColor(.gray.opacity(0.7)))
                                .keyboardType(.decimalPad)
                                .foregroundColor(.black)
                                .padding()
                                .onChange(of: pay) { newValue in
                                    let filtered = newValue.filter { $0.isNumber || $0 == "." }
                                    if filtered != newValue {
                                        pay = filtered
                                    }
                                }

                            Text("£/hr")
                                .foregroundColor(.gray)
                                .padding(.trailing, 16)
                        }
                        .background(Color.white)
                        .cornerRadius(12)

                        // Date & Time
                        VStack(spacing: 10) {
                            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)

                            DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Requirements Section
                    VStack(alignment: .leading, spacing: 14) {
                        sectionHeader("Job Requirements")

                        Text("Required Skills")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 4)

                        VStack(spacing: 8) {
                            ForEach(allSkills, id: \.self) { skill in
                                Button {
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
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)

                        Toggle("Requires Driving License", isOn: $requiresDrivingLicense)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .tint(accentBlue)
                    }
                    .padding(.horizontal, 20)

                    // Post Button
                    Button {
                        postJob()
                    } label: {
                        Text("Post Job")
                            .font(.headline)
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(formIsValid ? accentBlue : accentBlue.opacity(0.4))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(!formIsValid || isPosting)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
                .padding(.top, 16)
            }
            .scrollDismissesKeyboard(.interactively)

            // Loading overlay
            if isPosting {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                ProgressView("Posting job...")
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 10)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("New Job")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("Ok", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
    }

    private func styledField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField("", text: text, prompt: Text(placeholder).foregroundColor(.gray.opacity(0.7)))
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .foregroundColor(.black)
    }

    // MARK: - Post Job

    private func postJob() {
        guard !isPosting && formIsValid else { return }

        isPosting = true

        let skillsCopy = Array(selectedSkills)
        let requiresLicenseCopy = requiresDrivingLicense
        let titleCopy = jobTitle
        let locationCopy = location
        let payCopy = pay
        let dateCopy = selectedDate
        let timeCopy = selectedTime
        let latitude: Double = 51.5074
        let longitude: Double = -0.1278

        let geoPoint = GeoPoint(latitude: latitude, longitude: longitude)
        let combinedDate = combine(date: dateCopy, time: timeCopy)

        let newJob = Job(
            id: "",
            title: titleCopy,
            location: locationCopy,
            pay: payCopy,
            date: combinedDate,
            time: formattedTime(combinedDate),
            postedBy: "",
            status: "open",
            geoLocation: geoPoint,
            requiredSkills: skillsCopy,
            requiresDrivingLicense: requiresLicenseCopy
        )

        jobStore.addJob(newJob) { error in
            DispatchQueue.main.async {
                isPosting = false
                if let error = error {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                } else {
                    path.append(BusinessRoute.postSuccess)
                }
            }
        }
    }
}

func combine(date: Date, time: Date) -> Date {
    let calendar = Calendar.current
    var components = calendar.dateComponents([.year, .month, .day], from: date)
    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
    components.hour = timeComponents.hour
    components.minute = timeComponents.minute
    return calendar.date(from: components) ?? Date()
}

func formattedTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

#Preview {
    bPostNewJobForm(path: .constant(NavigationPath()))
        .environmentObject(JobStore())
}
