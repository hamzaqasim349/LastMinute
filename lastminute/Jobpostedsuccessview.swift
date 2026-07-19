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

    private let accentBlue = Color(red: 0.2, green: 0.4, blue: 0.8)

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.92, green: 0.95, blue: 1.0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Success icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 130, height: 130)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                }
                .padding(.bottom, 24)

                // Title
                Text("Job Posted!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
                    .padding(.bottom, 8)

                // Subtitle
                Text("Your job is now live and visible to nearby workers.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                // Buttons
                VStack(spacing: 14) {
                    Button {
                        path = NavigationPath()
                        path.append(SignUpRoute.businessDashboard)
                        path.append(BusinessRoute.newPost)
                    } label: {
                        Text("Post Another Job")
                            .font(.headline)
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(accentBlue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    Button {
                        path = NavigationPath()
                        path.append(SignUpRoute.businessDashboard)
                    } label: {
                        Text("Back to Dashboard")
                            .font(.headline)
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .foregroundColor(accentBlue)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(accentBlue, lineWidth: 1.5)
                            )
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 50)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
