//
//  PaymentPlanSelectionView.swift
//  lastminute
//
//  Created by Jabran Ali on 06/07/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PaymentPlanSelectionView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedPlan: String? = nil
    @State private var showCardDetail = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Your Payment Plan")
                .font(.title)
                .padding()
            
            Button(action: {
                selectedPlan = "payg"
                withAnimation {
                    showCardDetail = true
                }
            }) {
                HStack {
                    Text("Pay-As-You-Go")
                    Spacer()
                    if selectedPlan == "payg" {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            
            Button(action: {
                selectedPlan = "cash"
                withAnimation {
                    showCardDetail = true
                }
            }) {
                HStack {
                    Text("Cash-In-Hand (Monthly Subscription)")
                    Spacer()
                    if selectedPlan == "cash" {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            
            if showCardDetail {
                CardDetailsView()
                    .padding()
                    .transition(.opacity)
            }
            
            Spacer()
            
            Button("Proceed") {
                savePlanAndProceed()
            }
            .disabled(selectedPlan == nil || !showCardDetail)
            .padding()
            .frame(maxWidth: .infinity)
            .background((selectedPlan == nil || !showCardDetail) ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
    
    func savePlanAndProceed() {
        guard let plan = selectedPlan,
              let uid = authViewModel.user?.uid else {
            return
        }
        
        let db = Firestore.firestore()
        // Save the payment plan under the user's Firestore document
        db.collection("users").document(uid).updateData([
            "paymentPlan": plan
        ]) { error in
            if let error = error {
                print("Failed to save payment plan: \(error.localizedDescription)")
            } else {
                print("Payment plan saved successfully: \(plan)")
                // After saving, update screen to businessDashboard
                authViewModel.currentScreen = .businessDashboard
            }
        }
    }
}
