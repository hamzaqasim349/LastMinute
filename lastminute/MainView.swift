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
    
    private let strongOrange = Color(red: 1.0, green: 0.5, blue: 0.0)
    
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
    
    struct ProfileBubbleView: View {
        let totalEarnings: Double
        
        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white.opacity(0.8))
                    .shadow(radius: 5)
                    .frame(height: 100)
                    .padding(.horizontal, 20)
                
                HStack(spacing: 20) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Total Earnings")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("£\(totalEarnings, specifier: "%.2f")")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 30)
            }
            .padding(.top, 10)
        }
    }
    
    
    var body: some View {
        GeometryReader { geometry in
            
            ZStack(alignment: .bottomTrailing) {
                
                // MAIN CONTENT
                Group {
                    if let candidate = currentCandidate {
                        VStack(spacing: 20) {
                            
                            ProfileBubbleView(totalEarnings: 0.0)
                            
                            NavigationLink {
                                AdvertisedJobsView(isWorkerView: true, currentCandidate: candidate)
                            } label: {
                                VStack(alignment: .leading, spacing: 15) {
                                    
                                    HStack {
                                        Text("Nearby Jobs")
                                            .font(.title2)
                                            .bold()
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 15) {
                                            ForEach(Array(jobStore.eligibleJobs.prefix(5)), id: \.id) { job in
                                                JobCardView(job: job)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: geometry.size.height * 0.25)
                                .background(Color.white.opacity(0.3))
                                .cornerRadius(20)
                                .padding(.horizontal, 15)
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                            
                            // Bottom Navigation
                            HStack {
                                Spacer()
                                
                                NavigationLink {
                                    AdvertisedJobsView(isWorkerView: true, currentCandidate: candidate)
                                } label: {
                                    VStack {
                                        Image(systemName: "location.fill")
                                        Text("Nearby")
                                            .font(.caption)
                                    }
                                }
                                
                                Spacer()
                                
                                NavigationLink {
                                    CurrentJobsView()
                                } label: {
                                    VStack {
                                        Image(systemName: "briefcase.fill")
                                        Text("Current")
                                            .font(.caption)
                                    }
                                }
                                
                                Spacer()
                                
                                NavigationLink {
                                    JobHistoryViewWorkers()
                                } label: {
                                    VStack {
                                        Image(systemName: "clock.fill")
                                        Text("History")
                                            .font(.caption)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .background(Color(red: 0.97, green: 0.96, blue: 0.93))
                        }
                        .background(Color(red: 0.97, green: 0.96, blue: 0.93))
                    } else {
                        Text("❌ Candidate not found")
                            .foregroundColor(.red)
                    }
                }
                
                // 🔔 ALERT WIDGET
                PushNotificationWidget()
                    .frame(
                        width: geometry.size.width * 0.5,
                        height: geometry.size.height * 0.25
                    )
                    .padding(.bottom, 70)
                    .padding(.trailing, 16)
            }
        }
        .navigationTitle("Dashboard")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button {
                        authViewModel.currentScreen = .profileView
                    } label: {
                        Image(systemName: "person.crop.circle.fill")
                    }
                    
                    Button {
                        authViewModel.signOut()
                    } label: {
                        Image(systemName: "arrowshape.turn.up.left.fill")
                    }
                }
            }
        }
        .onChange(of: locationManager.userLocation) { location in
            guard
                let location,
                let candidate = currentCandidate
            else { return }
            
            jobStore.updateEligibleJobs(
                worker: candidate,
                userLocation: location
            )
        }
        .onChange(of: jobStore.businessadvertisedJobs) { _ in
            guard let candidate = currentCandidate else { return }
            
            let currentLoc = locationManager.userLocation ??
            CLLocation(latitude: 51.5074, longitude: -0.1278)
            
            jobStore.updateEligibleJobs(
                worker: candidate,
                userLocation: currentLoc
            )
        }
        .onAppear {
            if let userId = authViewModel.user?.uid {
                jobStore.startListeners(
                    for: userId,
                    userRole: authViewModel.userRole.rawValue
                )
            }
            
            if let location = locationManager.userLocation,
               let candidate = currentCandidate {
                jobStore.updateEligibleJobs(
                    worker: candidate,
                    userLocation: location
                )
            }
        }
    }
    
    
    // ⬇️ Job Card Component for the Widget
    struct JobCardView: View {
        let job: Job
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(job.title)
                    .font(.headline)
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(Color(red: 1.0, green: 0.5, blue: 0.0))
                    Text(job.location)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(Color(red: 1.0, green: 0.5, blue: 0.0))
                    Text(job.time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                HStack {
                    Text("Hello")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(Color(red: 1.0, green: 0.5, blue: 0.0))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .frame(width: 250, height: 140)
            .background(Color.white.opacity(0.8))
            .cornerRadius(15)
            .shadow(radius: 3)
        }
    }
    struct PushNotificationWidget: View {
        
        @EnvironmentObject var jobStore: JobStore
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                
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
                
                // Example dynamic alerts
                if !jobStore.businessAcceptedJobs.isEmpty {
                    Text("• Job accepted")
                }
                
                if !jobStore.eligibleJobs.isEmpty {
                    Text("• \(jobStore.eligibleJobs.count) nearby jobs")
                }
                
                if jobStore.businessadvertisedJobs.isEmpty {
                    Text("• No active jobs")
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
            .shadow(radius: 8)
        }
    }
}
