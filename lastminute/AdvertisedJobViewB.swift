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

    var body: some View {
        List {
            if isWorkerView {
                if jobStore.businessadvertisedJobs.isEmpty {
                    Text("No jobs currently advertised.")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    ForEach(jobStore.businessadvertisedJobs) { job in
                        JobRowView(
                            job: job,
                            isWorkerView: true,
                            currentCandidate: currentCandidate
                        )
                        .environmentObject(jobStore)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                    }
                }
            } else {
                if !jobStore.businessadvertisedJobs.isEmpty {
                    Section("Open Jobs") {
                        ForEach(jobStore.businessadvertisedJobs) { job in
                            JobRowView(
                                job: job,
                                isWorkerView: false,
                                currentCandidate: nil
                            )
                            .environmentObject(jobStore)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                        }
                    }
                }

                if !jobStore.businessAcceptedJobs.isEmpty {
                    Section("Accepted Jobs") {
                        ForEach(jobStore.businessAcceptedJobs) { job in
                            JobRowView(
                                job: job,
                                isWorkerView: false,
                                currentCandidate: nil
                            )
                            .environmentObject(jobStore)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                        }
                    }
                }

                if jobStore.businessadvertisedJobs.isEmpty && jobStore.businessAcceptedJobs.isEmpty {
                    Text("You haven't posted any jobs yet.")
                        .foregroundColor(.gray)
                        .italic()
                }
            }
        }
        .navigationTitle("Advertised Jobs")
        .scrollContentBackground(.hidden)
        .background(Color.white)
    }
}

struct JobRowView: View {
    @EnvironmentObject var jobStore: JobStore

    let job: Job
    let isWorkerView: Bool
    let currentCandidate: Candidate?

    @State private var remainingTime: TimeInterval = 0
    @State private var timer: Timer? = nil
    @State private var expandedCandidateID: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Top row with title and delete button
            HStack {
                Text(job.title)
                    .font(.headline)

                Spacer()

                if !isWorkerView {
                    Button(role: .destructive) {
                        jobStore.deleteJob(job)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }

            Text("Location: \(job.location)")
            Text("Pay: \(job.pay)")
            Text("Date: \(formattedDate(job.date))")
            Text("Time: \(job.time)")

            if remainingTime > 0 {
                let hours = Int(remainingTime) / 3600
                let minutes = (Int(remainingTime) % 3600) / 60
                let seconds = Int(remainingTime) % 60

                Text("Expires in: \(hours)h \(minutes)m \(seconds)s")
                    .foregroundColor(.red)
                    .font(.subheadline)
            } else {
                Text("Job expired")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }

            if isWorkerView, let candidate = currentCandidate {
                if !(job.candidates?.contains(where: { $0.id == candidate.id }) ?? false) && remainingTime > 0 {

                    Button("Apply") {
                        jobStore.applyToJob(job: job, candidate: candidate) { error in
                            if let error = error {
                                print("Error applying: \(error.localizedDescription)")
                            } else {
                                print("Applied successfully")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)

                } else if remainingTime > 0 {

                    Text("Already applied")
                        .foregroundColor(.gray)
                        .italic()
                }
            }

            if !isWorkerView {

                if let candidates = job.candidates, !candidates.isEmpty {

                    Text("Candidates Applied:")
                        .fontWeight(.semibold)

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
                                    } else {
                                        print("Candidate accepted successfully")
                                    }
                                }
                            }
                        )
                    }

                } else {
                    Text("No candidates applied yet.")
                        .foregroundColor(.gray)
                }

                if job.status == "accepted", let code = job.completionCode {

                    Text("Completion Code for Worker: \(code)")
                        .font(.headline)
                        .padding(.top, 8)
                        .foregroundColor(.green)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        )
        .padding(.vertical, 6)
        .padding(.horizontal, 10)

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

struct CandidateRowView: View {
    let candidate: Candidate
    let job: Job
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onAccept: () -> Void

    var isCandidateAccepted: Bool {
        if job.status == "accepted", let acceptedId = job.acceptedCandidate?.id {
            return acceptedId == candidate.id
        }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Only toggle expand
            Button(action: onToggleExpand) {
                HStack {
                    Text("\(candidate.name) \(candidate.surname) — \(candidate.experience)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
            }
            .buttonStyle(.plain) // Important! prevents it from inheriting parent tap behaviors
            .contentShape(Rectangle()) // Only the HStack is tappable

            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name: \(candidate.name) \(candidate.surname)")
                    Text("Age: \(candidate.age)")
                    Text("Phone: \(candidate.number)")
                    Text("Experience: \(candidate.experience)")
                    
                    // Accept button
                    if !isCandidateAccepted {
                        Button("Accept", action: onAccept)
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 4)
                    } else {
                        Text("Candidate accepted")
                            .foregroundColor(.green)
                            .italic()
                            .padding(.top, 4)
                    }
                }
                .padding(.leading, 8) // indentation to show expansion
            }
        }
        .padding(.vertical, 6)
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
                                                           skills: ["waiter"],      // wrap in an array
                                                               hasDrivingLicense: false ))
            .environmentObject(JobStore())
        }
    }

