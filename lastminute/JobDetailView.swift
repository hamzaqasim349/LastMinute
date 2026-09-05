//
//  JobDetailView.swift
//  lastminute
//
//  Created by Hamza Qasim on 30/06/2026.
//

import SwiftUI

struct JobDetailView: View {
    @EnvironmentObject var jobStore: JobStore
    let job: Job

    private let accentBlue = Color(red: 0.2, green: 0.4, blue: 0.8)

    @State private var expandedCandidateID: String? = nil
    @State private var remainingTime: TimeInterval = 0
    @State private var timer: Timer? = nil

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
                        detailRow(icon: "briefcase.fill", label: "Status", value: job.status.capitalized)

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
                            HStack(spacing: 4) {
                                Image(systemName: "timer")
                                    .font(.caption)
                                Text("Expires in \(hours)h \(minutes)m")
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

                    // Completion code
                    if job.status == "accepted", let code = job.completionCode {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.green)
                            Text("Completion Code: \(code)")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(14)
                    }

                    // Candidates
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Candidates (\(job.candidates?.count ?? 0))")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))

                        if let candidates = job.candidates, !candidates.isEmpty {
                            ForEach(candidates, id: \.id) { candidate in
                                CandidateRowView(
                                    candidate: candidate,
                                    job: job,
                                    isExpanded: expandedCandidateID == candidate.id,
                                    onToggleExpand: {
                                        withAnimation {
                                            expandedCandidateID = (expandedCandidateID == candidate.id) ? nil : candidate.id
                                        }
                                    },
                                    onAccept: { done in
                                        jobStore.acceptCandidate(job: job, candidate: candidate) { error in
                                            if let error = error {
                                                print("Error: \(error.localizedDescription)")
                                            }
                                            done()
                                        }
                                    },
                                    onReject: { done in
                                        jobStore.rejectCandidate(job: job, candidate: candidate) { error in
                                            if let error = error {
                                                print("Error rejecting: \(error.localizedDescription)")
                                            }
                                            done()
                                        }
                                    }
                                )
                                Divider()
                            }
                        } else {
                            Text("No candidates applied yet.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(14)
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
