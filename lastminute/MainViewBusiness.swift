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
    
    private let strongOrange = Color(red: 1.0, green: 0.5, blue: 0.0)
    
    enum BusinessTab {
        case create
        case advertised
        case history
    }

    var body: some View {
        GeometryReader { geometry in
            
            VStack(spacing: 0) {
                
                // 🔔 TOP NOTIFICATION BAR (25% height)
                BusinessNotificationWidget()
                    .frame(height: geometry.size.height * 0.25)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // 🔥 CONTENT AREA
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
                .background(Color.white)
                
                // 🔥 BOTTOM TOGGLE BAR
                HStack {
                    Spacer()
                    
                    tabButton(
                        icon: "plus.circle.fill",
                        title: "Post",
                        tab: .create
                    )
                    
                    Spacer()
                    
                    tabButton(
                        icon: "megaphone.fill",
                        title: "Advertised",
                        tab: .advertised
                    )
                    
                    Spacer()
                    
                    tabButton(
                        icon: "clock.fill",
                        title: "History",
                        tab: .history
                    )
                    
                    Spacer()
                }
                .padding(.vertical, 10)
                .background(Color.white)
            }
            .background(Color.white)
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationTitle("Dashboard")
        .navigationBarBackButtonHidden(true)
        
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 20) {
                    
                    Button(action: {
                        path.append(BusinessRoute.profile)
                    }) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        authViewModel.signOut()
                    }) {
                        Image(systemName: "power")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.red)
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
        VStack(alignment: .leading, spacing: 12) {
            
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
                Text("• A worker accepted your job")
                    .foregroundColor(.white)
            }
            
            if !jobStore.businessadvertisedJobs.isEmpty {
                Text("• \(jobStore.businessadvertisedJobs.count) active ads")
                    .foregroundColor(.white)
            }
            
            if jobStore.businessadvertisedJobs.isEmpty {
                Text("• No active job posts")
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.orange,
                            Color(red: 1.0, green: 0.5, blue: 0.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Tab Views

private extension MainViewBusiness {
    
    var createPostView: some View {
        VStack(spacing: 20) {
            Image(systemName: "plus.circle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Create a new job post")
                .font(.headline)
            
            Button("Create Post") {
                path.append(BusinessRoute.newPost)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var advertisedJobsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "megaphone")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("View your advertised jobs")
                .font(.headline)
            
            Button("Open Advertised Jobs") {
                path.append(BusinessRoute.advertisedJobs)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var jobHistoryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("View job history")
                .font(.headline)
            
            Button("Open History") {
                path.append(BusinessRoute.jobHistory)
            }
            .buttonStyle(.borderedProminent)
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
            VStack {
                Image(systemName: icon)
                    .foregroundColor(selectedTab == tab ? strongOrange : .gray)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(selectedTab == tab ? strongOrange : .gray)
            }
        }
    }
}
