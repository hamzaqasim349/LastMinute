//
//  WorkerJobDetailView.swift
//  lastminute
//
//  Created by Hamza Qasim on 30/06/2026.
//

import SwiftUI

struct WorkerJobDetailView: View {
    @EnvironmentObject var jobStore: JobStore
    let job: Job
    let candidate: Candidate?

    private let accentBlue = Color(red: 0.2, green: 0.4, blue: 0.8)

    @State private var remainingTime: TimeInterval = 0
    @State private var timer: Timer? = nil
    @State private var isApplying = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    private var hasApplied: Bool {
        guard let candidate = candidate else { return false }
        return job.candidates?.contains(where: { $0.id == candidate.id }) ?? false
    }

    private var isExpired: Bool {
        remainingTime <= 0
    }

    var body: some View {
        ZStack {
            Color(red: 0.92, green: 0.95, blue: 1.0)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Job info card
                    VStack(alignment: .leading, spacing: 12) {
                        Text(job.title)
                            .font(.title3.bold())
                            .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))

                        Divider()

                        detailRow(icon: "mappin.circle.fill", label: "Location", value: job.location)
                        detailRow(icon: "sterlingsign.circle.fill", label: "Pay", value: "\(job.pay) /hr")
                        detailRow(icon: "calendar", label: "Date", value: formattedDate(job.date))
                        detailRow(icon: "clock", label: "Time", value: job.time)

                        if !job.requiredSkills.isEmpty {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(accentBlue)
                                    .frame(width: 16)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Required Skills")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(job.requiredSkills.joined(separator: ", "))
                                        .font(.subheadline)
                                        .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
                                }
                            }
                        }

                        if job.requiresDrivingLicense == true {
                            HStack(spacing: 8) {
                                Image(systemName: "car.fill")
                                    .font(.caption)
                                    .foregroundColor(accentBlue)
                                    .frame(width: 16)
                                Text("Driving license required")
                                    .font(.subheadline)
                                    .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
                            }
                        }

                        // Expiry
                        if remainingTime > 0 {
                            let hours = Int(remainingTime) / 3600
                            let minutes = (Int(remainingTime) % 3600) / 60
                            let seconds = Int(remainingTime) % 60
                            HStack(spacing: 4) {
                                Image(systemName: "timer")
                                    .font(.caption)
                                Text("Expires in \(hours)h \(minutes)m \(seconds)s")
                                    .font(.caption)
                            }
                            .foregroundColor(.orange)
                            .padding(.top, 4)
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle")
                                    .font(.caption)
                                Text("Job expired")
                                    .font(.caption)
                            }
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(14)

                    // Apply section
                    applySection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Job Details")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
            }
        }
        .onAppear {
            updateRemainingTime()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                updateRemainingTime()
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("Ok", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Apply Section

    @ViewBuilder
    private var applySection: some View {
        if hasApplied {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("You've already applied to this job")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color.white)
            .cornerRadius(14)
        } else if isExpired {
            Text("This job has expired and can no longer be applied to.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color.white)
                .cornerRadius(14)
        } else {
            Button {
                applyToJob()
            } label: {
                HStack {
                    if isApplying {
                        ProgressView().tint(.white)
                    } else {
                        Text("Apply for this Job")
                            .font(.headline)
                            .bold()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(accentBlue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isApplying || candidate == nil)
        }
    }

    // MARK: - Apply Action

    private func applyToJob() {
        guard let candidate = candidate else {
            alertTitle = "Error"
            alertMessage = "Unable to identify your profile. Please try again."
            showAlert = true
            return
        }

        isApplying = true
        jobStore.applyToJob(job: job, candidate: candidate) { error in
            DispatchQueue.main.async {
                isApplying = false
                if let error = error {
                    alertTitle = "Application Failed"
                    alertMessage = error.localizedDescription
                } else {
                    alertTitle = "Applied!"
                    alertMessage = "Your application has been submitted successfully."
                }
                showAlert = true
            }
        }
    }

    // MARK: - Helpers

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(accentBlue)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func updateRemainingTime() {
        if let expiry = job.expiryDate {
            remainingTime = max(expiry.timeIntervalSinceNow, 0)
        } else {
            remainingTime = 0
        }
    }
}
