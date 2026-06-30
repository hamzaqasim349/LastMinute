//
//  AuthView.swift
//  lastminute
//
//  Created by Jabran Ali on 26/06/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import CoreLocation
enum AuthState {
    case loggedOut
    case loggedIn(userID: String, role: UserRole)
}

enum UserRole: String, Hashable, Equatable {
    case business
    case worker
    case unknown
}

enum AppScreen: Equatable {
    case login
    case signUp(role: UserRole)
    case loading
    case signUpChoice
    case workerDashboard
    case businessDashboard
    case businessPaymentSelection
    case profileView
    
    static func == (lhs: AppScreen, rhs: AppScreen) -> Bool {
        switch (lhs, rhs) {
        case (.login, .login),
             (.loading, .loading),
             (.workerDashboard, .workerDashboard),
             (.businessDashboard, .businessDashboard),
             (.businessPaymentSelection, .businessPaymentSelection):
            return true
        case let (.signUp(role1), .signUp(role2)):
            return role1 == role2
        default:
            return false
        }
    }
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: User? = nil
    @Published var userRole: UserRole = .unknown
    @Published var isLoading = false
    @Published var currentScreen: AppScreen = .loading
    @Published var locationManager = LocationManager() // inject
    
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    let jobStore: JobStore  // make accessible publicly for SignUpView
    
    init(jobStore: JobStore = JobStore()) {
        self.jobStore = jobStore
        if FirebaseApp.app() != nil {
            listenToAuthState()
        } else {
            print("❌ Firebase not configured.")
        }
    }
    
    func listenToAuthState() {
        guard FirebaseApp.app() != nil else {
            print("❌ Firebase not configured")
            return
        }
        
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.user = user
                print("📡 Auth state changed. Firebase user: \(String(describing: user?.uid))")
                
                if let uid = user?.uid {
                    let role = try await self.fetchUserRole(uid: uid)
                    self.userRole = role
                    print("✅ User role: \(role)")
                    
                    // Start job listeners after we know role
                    self.jobStore.startListeners(for: uid, userRole: role.rawValue)
                } else {
                    self.userRole = .unknown
                }
                
                // Update screen after role is resolved
                await self.updateCurrentScreen()
            }
        }
    }
    
    private func updateCurrentScreen() async {
        if user == nil {
            currentScreen = .login
        } else {
            switch userRole {
            case .worker:
                currentScreen = .workerDashboard
            case .business:
                do {
                    let hasPaymentPlan = try await fetchPaymentPlanCompleted(uid: user!.uid)
                    currentScreen = hasPaymentPlan ? .businessDashboard : .businessPaymentSelection
                } catch {
                    print("❌ Failed to fetch payment plan status: \(error.localizedDescription)")
                    currentScreen = .businessPaymentSelection
                }
            case .unknown:
                currentScreen = .loading
            }
        }
        print("🧭 Navigated to screen: \(currentScreen)")
    }
    
    func fetchUserRole(uid: String) async throws -> UserRole {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("users").document(uid).getDocument()
        
        guard let data = snapshot.data(),
              let roleString = data["role"] as? String else {
            print("❌ Role not found.")
            return .unknown
        }
        
        let resolved = UserRole(rawValue: roleString.lowercased()) ?? .unknown
        print("✅ fetchUserRole: \(resolved)")
        return resolved
    }
    
    func fetchPaymentPlanCompleted(uid: String) async throws -> Bool {
        let db = Firestore.firestore()
        let doc = try await db.collection("users").document(uid).getDocument()
        guard let data = doc.data(),
              let paymentPlan = data["paymentPlan"] as? String else {
            return false
        }
        return !paymentPlan.isEmpty
    }
    
    // MARK: - Async login/signup
    
    func signIn(email: String, password: String) async throws {
        await MainActor.run { self.isLoading = true }
        defer { Task { @MainActor in self.isLoading = false } }
        
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        let uid = result.user.uid
        
        let role = try await fetchUserRole(uid: uid)
        
        await MainActor.run {
            self.user = result.user
            self.userRole = role
            self.jobStore.startListeners(for: uid, userRole: role.rawValue)
            Task { await self.updateCurrentScreen() }
        }
    }
    
    func signUp(email: String, password: String, role: UserRole) async throws {
        await MainActor.run { self.isLoading = true }
        defer { Task { @MainActor in self.isLoading = false } }
        
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let uid = result.user.uid
        
        let db = Firestore.firestore()
        try await db.collection("users").document(uid).setData([
            "email": email,
            "role": role.rawValue,
            "createdAt": Timestamp(date: Date())
        ])
        
        await MainActor.run {
            self.user = result.user
            self.userRole = role
            self.jobStore.startListeners(for: uid, userRole: role.rawValue)
            
            if role == .business {
                self.currentScreen = .businessPaymentSelection
            } else {
                Task { await self.updateCurrentScreen() }
            }
        }
    }
    
    // MARK: - Completion versions
    
    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Task {
            do {
                try await signIn(email: email, password: password)
                await MainActor.run { completion(nil) }
            } catch { await MainActor.run { completion(error) } }
        }
    }
    
    func signUp(email: String, password: String, role: UserRole, completion: @escaping (Error?) -> Void) {
        Task {
            do {
                try await signUp(email: email, password: password, role: role)
                await MainActor.run { completion(nil) }
            } catch { await MainActor.run { completion(error) } }
        }
    }
    
    func signOut() {
        guard FirebaseApp.app() != nil else { return }
        try? Auth.auth().signOut()
        user = nil
        userRole = .unknown
        currentScreen = .login
        print("🚪 Signed out")
    }
    
    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func saveWorkerLocation(_ location: CLLocation) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .setData([
                "location": GeoPoint(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            ], merge: true)
    }
    
    
}
