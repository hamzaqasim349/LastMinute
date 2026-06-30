//
//  lastminuteApp.swift
//  lastminute
//
//  Created by Jabran Ali on 20/06/2025.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore



class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()

        let settings = FirestoreSettings()
        settings.cacheSettings = MemoryCacheSettings() // This disables persistence (no disk caching)
        Firestore.firestore().settings = settings

        return true
    }
}


@main
struct lastminuteApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var jobStore = JobStore()
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(jobStore)
            
        }
    }
}
