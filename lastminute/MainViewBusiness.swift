//
//  MainViewBusiness.swift
//  lastminute
//
//  Created by Jabran Ali on 21/06/2025.
//

import SwiftUI
import FirebaseFirestore

enum BusinessRoute: Hashable {
    case newPost
    case postSuccess
    case advertisedJobs
    case jobHistory
    case profile
}

struct MainViewBusiness: View {
    @Binding var path: NavigationPath
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var businessProfileImage: Image? = nil
    @State private var selectedTab: BusinessTab = .advertised

    private let accentBlue = Color(red: 0.2, green: 0.4, blue: 0.8)

    enum BusinessTab {
        case create
        case advertised
        case history
    }

    var body: some View {
        VStack(spacing: 0) {

            // Notification widget - auto-sized
            BusinessNotificationWidget()
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)

            // Content area
            Group {
                switch selectedTab {
                case .create:
                    createPostView
                case .advertised:
                    advertisedJobsView
                case .history:
                    jobHistoryView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom tab bar
            HStack {
                Spacer()
                tabButton(icon: "plus.circle.fill", title: "Post", tab: .create)
                Spacer()
                tabButton(icon: "megaphone.fill", title: "Advertised", tab: .advertised)
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
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        path.append(BusinessRoute.profile)
                    } label: {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                    }

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
        }
        .onAppear {
            guard let uid = authViewModel.user?.uid else { return }
            let userDocRef = Firestore.firestore().collection("users").document(uid)
            userDocRef.getDocument { document, error in
                if let error = error {
                    print("Error fetching user role: \(error.localizedDescription)")
                    return
                }
                guard let data = document?.data(),
                      let role = data["role"] as? String else { return }

                DispatchQueue.main.async {
                    jobStore.startListeners(for: uid, userRole: role)
                }
            }
        }
    }
}

// MARK: - Notification Widget

struct BusinessNotificationWidget: View {
    @EnvironmentObject var jobStore: JobStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(.white)

                Text("Business Alerts")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()
            }

            Divider()
                .background(Color.white.opacity(0.4))

            if !jobStore.businessAcceptedJobs.isEmpty {
                Label("A worker accepted your job", systemImage: "person.fill.checkmark")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }

            if !jobStore.businessadvertisedJobs.isEmpty {
                Label("\(jobStore.businessadvertisedJobs.count) active ads", systemImage: "megaphone.fill")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }

            if jobStore.businessadvertisedJobs.isEmpty {
                Label("No active job posts", systemImage: "tray")
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

// MARK: - Tab Views

private extension MainViewBusiness {

    var createPostView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "plus.circle")
                .font(.system(size: 50))
                .foregroundColor(accentBlue)

            Text("Create a new job post")
                .font(.headline)
                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))

            Text("Reach nearby workers instantly")
                .font(.subheadline)
                .foregroundColor(.gray)

            Button {
                path.append(BusinessRoute.newPost)
            } label: {
                Text("Create Post")
                    .bold()
                    .frame(maxWidth: 180)
                    .padding(.vertical, 12)
                    .background(accentBlue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 4)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var advertisedJobsView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "megaphone")
                .font(.system(size: 50))
                .foregroundColor(accentBlue)

            Text("Your advertised jobs")
                .font(.headline)
                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))

            Text("Manage candidates and active posts")
                .font(.subheadline)
                .foregroundColor(.gray)

            Button {
                path.append(BusinessRoute.advertisedJobs)
            } label: {
                Text("View Jobs")
                    .bold()
                    .frame(maxWidth: 180)
                    .padding(.vertical, 12)
                    .background(accentBlue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 4)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var jobHistoryView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "clock")
                .font(.system(size: 50))
                .foregroundColor(accentBlue)

            Text("Job history")
                .font(.headline)
                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))

            Text("Completed and past job posts")
                .font(.subheadline)
                .foregroundColor(.gray)

            Button {
                path.append(BusinessRoute.jobHistory)
            } label: {
                Text("View History")
                    .bold()
                    .frame(maxWidth: 180)
                    .padding(.vertical, 12)
                    .background(accentBlue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 4)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Tab Button

private extension MainViewBusiness {

    @ViewBuilder
    func tabButton(icon: String, title: String, tab: BusinessTab) -> some View {
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
}
