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

    let allSkills = ["Cashier", "Delivery Driver", "Stock Replenisher", "Waiter", "Cook/Chef"]
    @State private var selectedSkills: Set<String> = []
    @State private var requiresDrivingLicense = false

    var formIsValid: Bool {
        !jobTitle.isEmpty && !location.isEmpty && !pay.isEmpty && !selectedSkills.isEmpty
    }

    var body: some View {
        Form {

            // -------------------------
            // Job Info Section
            // -------------------------
            Section(header: Text("Job Info")) {
                TextField("Job Title", text: $jobTitle)
                TextField("Location", text: $location)

                HStack {
                    TextField("Pay", text: $pay)
                        .keyboardType(.decimalPad)
                    Text("£/hr").foregroundColor(.gray)
                }

                DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
            }

            // -------------------------
            // Skills + Requirements
            // -------------------------
            Section(header: Text("Job Requirements")) {

                Text("Required Skills")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                ForEach(allSkills, id: \.self) { skill in
                    bPostJobFormMultipleSelectionRow(
                        title: skill,
                        isSelected: Binding(
                            get: { selectedSkills.contains(skill) },
                            set: { newValue in
                                if newValue {
                                    selectedSkills.insert(skill)
                                } else {
                                    selectedSkills.remove(skill)
                                }
                            }
                        )
                    )
                }

                Toggle("Requires Driving License", isOn: $requiresDrivingLicense)
            }

            // -------------------------
            // Post Button
            // -------------------------
            Button(action: {
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

                print("Posting Job with skills: \(skillsCopy), requiresDrivingLicense: \(requiresLicenseCopy)")

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
                            print("Error posting job: \(error.localizedDescription)")
                        } else {
                            path.append(BusinessRoute.postSuccess)
                        }
                    }
                }

            }) {
                Text("Post Job")
            }
            .disabled(!formIsValid || isPosting)

        } // END FORM
        .navigationTitle("New Job")
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


// ✅ Helper view for multi-select skills
struct bPostJobFormMultipleSelectionRow: View {
    let title: String
    @Binding var isSelected: Bool     // ✅ Now a Binding

    var body: some View {
        Button {
            isSelected.toggle()        // ✅ No action parameter needed
        } label: {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}



#Preview {
    bPostNewJobForm(path: .constant(NavigationPath()))
        .environmentObject(JobStore())
}


