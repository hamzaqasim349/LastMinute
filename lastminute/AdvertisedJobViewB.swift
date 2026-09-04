//
//  AdvertisedJobViewB.swift
//  lastminute
//
//  Created by Jabran Ali on 22/06/2025.
//
import SwiftUI

struct AdvertisedJobsView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var authViewModel: AuthViewModel

    let isWorkerView: Bool
    let currentCandidate: Candidate?

    private let accentBlue = Color(red: 0.2, green: 0.4, blue: 0.8)

    var body: some View {
        ZStack {
            Color(red: 0.92, green: 0.95, blue: 1.0)
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 14) {
                    if isWorkerView {
                        if jobStore.businessadvertisedJobs.isEmpty {
                            emptyState(icon: "megaphone", message: "No jobs currently advertised.")
                        } else {
                            ForEach(jobStore.businessadvertisedJobs) { job in
                                NavigationLink {
                                    WorkerJobDetailView(job: job, candidate: currentCandidate)
                                        .environmentObject(jobStore)
                                } label: {
                                    JobRowView(
                                        job: job,
                                        isWorkerView: true,
                                        currentCandidate: currentCandidate
                                    )
                                    .environmentObject(jobStore)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        if !jobStore.businessadvertisedJobs.isEmpty {
                            sectionHeader("Open Jobs")
                            ForEach(jobStore.businessadvertisedJobs) { job in
                                JobRowView(
                                    job: job,
                                    isWorkerView: false,
                                    currentCandidate: nil
                                )
                                .environmentObject(jobStore)
                            }
                        }

                        if !jobStore.businessAcceptedJobs.isEmpty {
                            sectionHeader("Accepted Jobs")
                            ForEach(jobStore.businessAcceptedJobs) { job in
                                JobRowView(
                                    job: job,
                                    isWorkerView: false,
                                    currentCandidate: nil
                                )
                                .environmentObject(jobStore)
                            }
                        }

                        if jobStore.businessadvertisedJobs.isEmpty && jobStore.businessAcceptedJobs.isEmpty {
                            emptyState(icon: "tray", message: "You haven't posted any jobs yet.")
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .refreshable {
                await jobStore.refresh()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Advertised Jobs")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
            Spacer()
        }
        .padding(.top, 8)
    }

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 12) {
            Spacer(minLength: 80)
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundColor(.gray.opacity(0.5))
            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Job Row

struct JobRowView: View {
    @EnvironmentObject var jobStore: JobStore

    let job: Job
    let isWorkerView: Bool
    let currentCandidate: Candidate?

    private let accentBlue = Color(red: 0.2, green: 0.4, blue: 0.8)

    @State private var remainingTime: TimeInterval = 0
    @State private var timer: Timer? = nil
    @State private var expandedCandidateID: String? = nil
    @State private var showDeleteAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Header: title + delete
            HStack {
                Text(job.title)
                    .font(.headline)
                    .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))

                Spacer()

                if !isWorkerView {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .alert("Delete Job", isPresented: $showDeleteAlert) {
                        Button("Cancel", role: .cancel) { }
                        Button("Delete", role: .destructive) {
                            jobStore.deleteJob(job)
                        }
                    } message: {
                        Text("Are you sure you want to delete this job? This action cannot be undone.")
                    }
                }
            }

            // Job details
            VStack(alignment: .leading, spacing: 6) {
                jobDetailRow(icon: "mappin.circle.fill", text: job.location)
                jobDetailRow(icon: "sterlingsign.circle.fill", text: "\(job.pay) /hr")
                jobDetailRow(icon: "calendar", text: formattedDate(job.date))
                jobDetailRow(icon: "clock", text: job.time)
            }

            // Expiry timer
            if remainingTime > 0 {
                let hours = Int(remainingTime) / 3600
                let minutes = (Int(remainingTime) % 3600) / 60
                let seconds = Int(remainingTime) % 60

                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.caption)
                    Text("Expires in: \(hours)h \(minutes)m \(seconds)s")
                        .font(.caption)
                }
                .foregroundColor(.orange)
                .padding(.top, 2)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle")
                        .font(.caption)
                    Text("Job expired")
                        .font(.caption)
                }
                .foregroundColor(.gray)
                .padding(.top, 2)
            }

            // Worker: applied status + tap hint (apply happens on detail screen)
            if isWorkerView, let candidate = currentCandidate {
                if job.candidates?.contains(where: { $0.id == candidate.id }) ?? false {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("Applied")
                            .font(.caption)
                            .foregroundColor(.green)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 4)
                } else {
                    HStack {
                        Text("Tap to view & apply")
                            .font(.caption)
                            .foregroundColor(accentBlue)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 4)
                }
            }

            // Business: Candidates
            if !isWorkerView {
                if let candidates = job.candidates, !candidates.isEmpty {
                    Divider()
                        .padding(.vertical, 4)

                    Text("Candidates (\(candidates.count))")
                        .font(.subheadline.bold())
                        .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))

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
                            onAccept: {
                                jobStore.acceptCandidate(job: job, candidate: candidate) { error in
                                    if let error = error {
                                        print("Error accepting candidate: \(error.localizedDescription)")
                                    }
                                }
                            }
                        )
                    }
                } else {
                    Text("No candidates applied yet.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }

                // Completion code
                if job.status == "accepted", let code = job.completionCode {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                        Text("Completion Code: \(code)")
                            .font(.subheadline.bold())
                            .foregroundColor(.green)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
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

    private func jobDetailRow(icon: String, text: String) -> some View {
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

// MARK: - Candidate Row

struct CandidateRowView: View {
    let candidate: Candidate
    let job: Job
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onAccept: () -> Void

    private let accentBlue = Color(red: 0.2, green: 0.4, blue: 0.8)

    var isCandidateAccepted: Bool {
        if job.status == "accepted", let acceptedId = job.acceptedCandidate?.id {
            return acceptedId == candidate.id
        }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: onToggleExpand) {
                HStack {
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundColor(accentBlue)
                    Text("\(candidate.name) \(candidate.surname)")
                        .font(.subheadline)
                        .foregroundColor(accentBlue)
                    Text("• \(candidate.experience)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    detailRow("Name", value: "\(candidate.name) \(candidate.surname)")
                    detailRow("Age", value: "\(candidate.age)")
                    detailRow("Phone", value: candidate.number)
                    detailRow("Experience", value: candidate.experience)

                    if !isCandidateAccepted {
                        Button {
                            onAccept()
                        } label: {
                            Text("Accept Candidate")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.top, 4)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Candidate accepted")
                                .foregroundColor(.green)
                                .italic()
                        }
                        .font(.subheadline)
                        .padding(.top, 4)
                    }
                }
                .padding(.leading, 24)
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text("\(label):")
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.caption)
                .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
        }
    }
}

#Preview {
    NavigationView {
        AdvertisedJobsView(isWorkerView: true,
                           currentCandidate: Candidate(id: "user123",
                                                       name: "John",
                                                       surname: "Doe",
                                                       experience: "2 years",
                                                       age: 30,
                                                       number: "123-456-7890",
                                                       skills: ["waiter"],
                                                       hasDrivingLicense: false))
        .environmentObject(JobStore())
    }
}
