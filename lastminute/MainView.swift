//
//  MainView.swift
//  lastminute
//
//  Created by Jabran Ali on 21/06/2025.
//
import SwiftUI
import CoreLocation

struct MainView: View {
    let currentUserID: String

    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var locationManager = LocationManager()

    @State private var selectedTab: WorkerTab = .nearby

    private let accentBlue = Color(red: 0.2, green: 0.4, blue: 0.8)

    enum WorkerTab {
        case nearby
        case current
        case history
    }

    var currentCandidate: Candidate? {
        guard !currentUserID.isEmpty else { return nil }
        return Candidate(
            id: currentUserID,
            name: "John",
            surname: "Doe",
            experience: "3 years",
            age: 24,
            number: "07563278653",
            skills: ["waiter"],
            hasDrivingLicense: false
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Notification widget
            WorkerNotificationWidget()
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)

            // Content
            Group {
                switch selectedTab {
                case .nearby:
                    nearbyView
                case .current:
                    CurrentJobsView()
                case .history:
                    JobHistoryViewWorkers()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom tab bar
            HStack {
                Spacer()
                tabButton(icon: "location.fill", title: "Nearby", tab: .nearby)
                Spacer()
                tabButton(icon: "briefcase.fill", title: "Current", tab: .current)
                Spacer()
                tabButton(icon: "clock.fill", title: "History", tab: .history)
                Spacer()
            }
            .padding(.vertical, 10)
            .background(Color.white)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: -2)
        }
        .background(Color(red: 0.92, green: 0.95, blue: 1.0))
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle("Dashboard")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    authViewModel.currentScreen = .profileView
                } label: {
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundColor(accentBlue)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    authViewModel.signOut()
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 18))
                        .foregroundColor(.red.opacity(0.8))
                }
                .accessibilityLabel("Sign Out")
            }
        }
        .onChange(of: locationManager.userLocation) { location in
            guard let location, let candidate = currentCandidate else { return }
            jobStore.updateEligibleJobs(worker: candidate, userLocation: location)
        }
        .onChange(of: jobStore.businessadvertisedJobs) { _ in
            guard let candidate = currentCandidate else { return }
            let currentLoc = locationManager.userLocation ?? CLLocation(latitude: 51.5074, longitude: -0.1278)
            jobStore.updateEligibleJobs(worker: candidate, userLocation: currentLoc)
        }
        .onAppear {
            if let userId = authViewModel.user?.uid {
                jobStore.startListeners(for: userId, userRole: authViewModel.userRole.rawValue)
            }
            if let location = locationManager.userLocation, let candidate = currentCandidate {
                jobStore.updateEligibleJobs(worker: candidate, userLocation: location)
            }
        }
    }

    // MARK: - Nearby View

    private var nearbyView: some View {
        Group {
            if let candidate = currentCandidate {
                ScrollView {
                    VStack(spacing: 20) {
                        // Earnings card
                        ProfileBubbleView(totalEarnings: 0.0)
                            .id("earnings")

                        // Nearby jobs section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Nearby Jobs")
                                    .font(.headline)
                                    .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
                                Spacer()
                                NavigationLink {
                                    AdvertisedJobsView(isWorkerView: true, currentCandidate: candidate)
                                } label: {
                                    Text("View All")
                                        .font(.subheadline.bold())
                                        .foregroundColor(accentBlue)
                                }
                            }

                            if jobStore.eligibleJobs.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "location.slash")
                                        .font(.system(size: 36))
                                        .foregroundColor(.gray.opacity(0.4))
                                    Text("No nearby jobs found")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(Array(jobStore.eligibleJobs.prefix(5)), id: \.id) { job in
                                        NavigationLink {
                                            AdvertisedJobsView(isWorkerView: true, currentCandidate: candidate)
                                        } label: {
                                            JobCardView(job: job)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 20)
                }
                .refreshable {
                    await jobStore.refresh()
                    let currentLoc = locationManager.userLocation ?? CLLocation(latitude: 51.5074, longitude: -0.1278)
                    jobStore.updateEligibleJobs(worker: candidate, userLocation: currentLoc)
                }
            } else {
                VStack {
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .font(.system(size: 44))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("Candidate not found")
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Tab Button

    @ViewBuilder
    private func tabButton(icon: String, title: String, tab: WorkerTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(selectedTab == tab ? accentBlue : .gray)
                Text(title)
                    .font(.caption2.bold())
                    .foregroundColor(selectedTab == tab ? accentBlue : .gray)
            }
        }
    }

    // MARK: - Earnings Card

    struct ProfileBubbleView: View {
        let totalEarnings: Double
        private let accentBlue = Color(red: 0.2, green: 0.4, blue: 0.8)

        var body: some View {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(accentBlue.opacity(0.12))
                        .frame(width: 56, height: 56)
                    Image(systemName: "sterlingsign.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(accentBlue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Earnings")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("£\(totalEarnings, specifier: "%.2f")")
                        .font(.title2.bold())
                        .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
                }

                Spacer()
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Job Card

    struct JobCardView: View {
        let job: Job
        private let accentBlue = Color(red: 0.2, green: 0.4, blue: 0.8)

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(job.title)
                        .font(.subheadline.bold())
                        .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                HStack(spacing: 12) {
                    Label(job.location, systemImage: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Label("\(job.pay) /hr", systemImage: "sterlingsign.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Label(job.time, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 2)
        }
    }

    // MARK: - Notification Widget

    struct WorkerNotificationWidget: View {
        @EnvironmentObject var jobStore: JobStore

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .foregroundColor(.white)
                    Text("Alerts")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }

                Divider()
                    .background(Color.white.opacity(0.4))

                if !jobStore.workerActiveJobs.isEmpty {
                    Label("You have \(jobStore.workerActiveJobs.count) active job(s)", systemImage: "briefcase.fill")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }

                if !jobStore.eligibleJobs.isEmpty {
                    Label("\(jobStore.eligibleJobs.count) nearby jobs available", systemImage: "location.fill")
                        .font(.subheadline)
                        .foregroundColor(.white)
                } else {
                    Label("No nearby jobs right now", systemImage: "location.slash")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.5, green: 0.7, blue: 1.0),
                                Color(red: 0.2, green: 0.4, blue: 0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
    }
}
