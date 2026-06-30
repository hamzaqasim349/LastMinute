//
//  RootView.swift
//  lastminute
//
//  Created by Jabran Ali on 26/06/2025.
//
import SwiftUI

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var jobStore: JobStore
    @State private var path = NavigationPath()
    @State private var profileImage: Image? = nil
    
    var body: some View {
        NavigationStack(path: $path) {
            Group {
                switch authViewModel.currentScreen {
                case .login:
                    loginScreen
                case .signUpChoice:
                    SignUpChoiceView(path: $path)
                        .environmentObject(authViewModel)
                case .signUp(let role):
                    SignUpView(path: $path, role: role)
                        .environmentObject(authViewModel)
                case .workerDashboard, .businessDashboard:
                    // Show loading until path is ready
                    if !isPathReady(for: authViewModel.currentScreen) {
                        ProgressView("Loading dashboard…")
                    } else {
                        EmptyView() // Navigation handled by path
                    }
                case .profileView:
                    ProfileView(profileImage: $profileImage)
                        .environmentObject(authViewModel)
                        .environmentObject(jobStore)
                    
                case .businessPaymentSelection:
                    PaymentPlanSelectionView()
                case .loading:
                    ProgressView("Loading…")
                    
                }
            }
            // Navigation destinations for SignUpRoute
            .navigationDestination(for: SignUpRoute.self) { route in
                switch route {
                case .choice:
                    SignUpChoiceView(path: $path)
                        .environmentObject(authViewModel)
                case .form(let role):
                    SignUpView(path: $path, role: role)
                        .environmentObject(authViewModel)
                case .login:
                    LogInView()
                        .environmentObject(authViewModel)
                case .signUp(let role):
                    SignUpView(path: $path, role: role)
                        .environmentObject(authViewModel)
                case .paymentPlan:
                    PaymentPlanSelectionView()
                        .environmentObject(authViewModel)
                case .workerDashboard(let userID):
                    MainView(currentUserID: userID)
                        .environmentObject(jobStore)
                        .environmentObject(authViewModel)
                case .businessDashboard:
                    MainViewBusiness(path: $path)
                        .environmentObject(jobStore)
                        .environmentObject(authViewModel)
                }
            }
            // Navigation destinations for BusinessRoute
            .navigationDestination(for: BusinessRoute.self) { route in
                switch route {
                case .newPost:
                    bPostNewJobForm(path: $path)
                        .environmentObject(jobStore)
                case .postSuccess:
                    JobPostedSuccessView(path: $path)
                        .environmentObject(jobStore)
                case .advertisedJobs:
                    AdvertisedJobsView(isWorkerView: false, currentCandidate: nil)
                        .environmentObject(jobStore)
                case .jobHistory:
                    JobHistoryView()
                        .environmentObject(jobStore)
                case .profile:
                       bizProfileView(profileImage: $profileImage)
                           .environmentObject(authViewModel)
                           .environmentObject(jobStore)
                }
            }
        }
        .onChange(of: authViewModel.currentScreen) { _, newScreen in
            updatePath(for: newScreen)
        }
    }
    
    // MARK: - Check if path is ready
    private func isPathReady(for screen: AppScreen) -> Bool {
        switch screen {
        case .workerDashboard:
            return authViewModel.user?.uid != nil
        default:
            return true
        }
    }
    
    // MARK: - Update navigation path
    private func updatePath(for screen: AppScreen) {
        path = NavigationPath() // reset path
        
        switch screen {
        case .workerDashboard:
            guard let uid = authViewModel.user?.uid else { return }
            path.append(SignUpRoute.workerDashboard(userID: uid))
        case .businessDashboard:
            path.append(SignUpRoute.businessDashboard)
        default:
            break
        }
    }
    
    // MARK: - Login screen with sign up button
    private var loginScreen: some View {
        LogInView()
            .environmentObject(authViewModel)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Up") {
                        path.append(SignUpRoute.choice)
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.8))
                }
            }
    }
}
