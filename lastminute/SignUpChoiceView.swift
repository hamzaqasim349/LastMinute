//
//  SignUpChoice.swift
//  lastminute
//
//  Created by Jabran Ali on 21/06/2025.
//
import SwiftUI

enum SignUpRoute: Hashable {
    case choice
    case form(UserRole)
    case login
    case signUp(role: UserRole)
    case paymentPlan
    case workerDashboard(userID: String)
    case businessDashboard
}


struct SignUpChoiceView: View {
    @Binding var path: NavigationPath

    var body: some View {
        ZStack {
            // Background gradient matching login
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.7, green: 0.85, blue: 1.0), Color(red: 0.85, green: 0.9, blue: 1.0)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Title section
                VStack(spacing: 4) {
                    Text("Join as")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))

                    Text("Choose how you'd like to get started")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.55))
                }
                .padding(.top, 40)
                .padding(.bottom, 24)

                Spacer()

                // Cards
                VStack(spacing: 20) {
                    // Business card
                    Button {
                        path.append(SignUpRoute.form(.business))
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Business")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)

                                Text("Post jobs and find workers")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.85))
                            }

                            Spacer()

                            Image(systemName: "building.2.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(24)
                        .background(Color(red: 0.2, green: 0.4, blue: 0.8))
                        .cornerRadius(16)
                    }

                    // Worker card
                    Button {
                        path.append(SignUpRoute.form(.worker))
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Worker")
                                    .font(.title2.bold())
                                    .foregroundColor(Color(red: 0.15, green: 0.2, blue: 0.4))

                                Text("Find nearby jobs and get hired")
                                    .font(.subheadline)
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.5))
                            }

                            Spacer()

                            Image(systemName: "person.fill.checkmark")
                                .font(.system(size: 32))
                                .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.8))
                        }
                        .padding(24)
                        .background(Color.white.opacity(0.85))
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 28)

                Spacer()
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
