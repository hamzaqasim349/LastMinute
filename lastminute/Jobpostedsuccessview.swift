//
//  Jobpostedsuccessview.swift
//  lastminute
//
//  Created by Jabran Ali on 24/06/2025.
//
import SwiftUI

struct JobPostedSuccessView: View {
    @Binding var path: NavigationPath
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)

            Text("Job Posted Successfully!")
                .font(.title)
                .fontWeight(.semibold)

            Text("Your job is now live and visible to workers.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Post Another Job") {
                // Clear navigation stack and navigate to new post form
                path = NavigationPath()
                path.append(BusinessRoute.newPost)
            }
            .padding(.top, 40)

            Button("Back to Dashboard") {
                // Clear navigation stack and go to dashboard
                path = NavigationPath()
                path.append(SignUpRoute.businessDashboard)
            }
        }
        .padding()
        // Hide the back button on this screen
        .navigationBarBackButtonHidden(true)
        // Also hide it on the next dashboard view
        .onAppear {
            UINavigationBar.appearance().topItem?.hidesBackButton = true
        }
    }
}
