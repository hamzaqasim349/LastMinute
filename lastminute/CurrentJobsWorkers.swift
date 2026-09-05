//
//  CurrentJobsWorkers.swift
//  lastminute
//
//  Created by Jabran Ali on 25/06/2025.
//

import SwiftUI
import FirebaseFirestore

struct CurrentJobsView: View {
    @EnvironmentObject var jobStore: JobStore

    @State private var selectedJob: Job? = nil
    @State private var enteredCode: String = ""
    @State private var showCodeEntry: Bool = false
    @State private var statusPopup: StatusPopupData? = nil

    private let accentBlue = Color(red: 0.2, green: 0.4, blue: 0.8)

    private var acceptedJobs: [Job] {
        jobStore.activeJobs.filter { $0.status == "accepted" }
    }

    var body: some View {
        ZStack {
            Color(red: 0.92, green: 0.95, blue: 1.0)
                .ignoresSafeArea()

            if acceptedJobs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "briefcase")
                        .font(.system(size: 44))
                        .foregroundColor(.gray.opacity(0.4))
                    Text("No accepted jobs yet")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(acceptedJobs) { job in
                            currentJobCard(job)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Current Jobs")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
            }
        }
        .alert("Enter Completion Code", isPresented: $showCodeEntry, actions: {
            TextField("Code", text: $enteredCode)
            Button("Submit") { verifyCode() }
            Button("Cancel", role: .cancel) {
                selectedJob = nil
                enteredCode = ""
            }
        }, message: {
            Text("Please enter the completion code provided by the business.")
        })
        .statusPopup($statusPopup)
    }

    // MARK: - Job Card

    private func currentJobCard(_ job: Job) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with status badge
            HStack {
                Text(job.title)
                    .font(.headline)
                    .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
                Spacer()
                Text("Accepted")
                    .font(.caption2.bold())
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.12))
                    .cornerRadius(6)
            }

            // Details
            VStack(alignment: .leading, spacing: 6) {
                detailRow(icon: "mappin.circle.fill", text: job.location)
                detailRow(icon: "sterlingsign.circle.fill", text: "\(job.pay) /hr")
                detailRow(icon: "calendar", text: formattedDate(job.date))
                detailRow(icon: "clock", text: job.time)
            }

            Divider()

            // Complete button
            Button {
                selectedJob = job
                enteredCode = ""
                showCodeEntry = true
            } label: {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                    Text("Enter Completion Code")
                        .bold()
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(accentBlue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private func detailRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(accentBlue)
                .frame(width: 16)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Verify Code

    func verifyCode() {
        guard let job = selectedJob else { return }

        // Close the code-entry dialog first
        showCodeEntry = false

        if enteredCode.uppercased() == job.completionCode?.uppercased() {
            let jobRef = Firestore.firestore().collection("jobs").document(job.id)

            jobRef.updateData(["status": "completed"]) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        statusPopup = StatusPopupData(kind: .error, title: "Error", message: "Could not mark job complete: \(error.localizedDescription)")
                    } else {
                        jobStore.workerActiveJobs.removeAll { $0.id == job.id }
                        jobStore.activeJobs.removeAll { $0.id == job.id }
                        statusPopup = StatusPopupData(kind: .success, title: "Job Completed", message: "The job has been marked as complete.")
                    }
                    selectedJob = nil
                    enteredCode = ""
                }
            }
        } else {
            statusPopup = StatusPopupData(kind: .error, title: "Incorrect Code", message: "The completion code you entered is incorrect. Please try again.")
            enteredCode = ""
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
