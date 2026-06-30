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
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Top - Business section with gradient transition
                ZStack {
                    // Gradient from blue to white
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(red: 0.7, green: 0.85, blue: 1.0), location: 0.0),
                            .init(color: Color(red: 0.85, green: 0.9, blue: 1.0), location: 0.4),
                            .init(color: .white, location: 1.05)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    Text("Business")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                }
                .frame(height: geo.size.height * 0.55) // slightly larger top section
                .onTapGesture {
                    path.append(SignUpRoute.form(.business))
                }

                // Bottom - Worker section
                ZStack {
                    Color.white

                    Text("Worker")
                        .font(.largeTitle.bold())
                        .foregroundColor(.blue)
                        .padding(.bottom, 10)
                }
                .frame(height: geo.size.height * 0.3)
                .onTapGesture {
                    path.append(SignUpRoute.form(.worker))
                }
            }
            .ignoresSafeArea()
        }
        .navigationTitle("Sign Up Choice")
        .navigationBarTitleDisplayMode(.inline)
    }
}
