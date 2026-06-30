//
//  BusinessSubcriptionmode.swift
//  lastminute
//
//  Created by Jabran Ali on 21/07/2025.
//

import SwiftUI
import Stripe
import FirebaseFunctions
import FirebaseAuth
import StripePaymentSheet
import FirebaseFirestore

struct BusinessSubscriptionView: View {
    @State private var isSubscribed = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var paymentSheet: PaymentSheet?

    // Replace with your Stripe Price ID
    private let priceId = "price_1234567890abcdef"

    var body: some View {
        VStack(spacing: 24) {
            Text("Cash-in-Hand Worker Access")
                .font(.title2)
                .bold()

            if isLoading {
                ProgressView("Processing...")
            } else if isSubscribed {
                Text("✅ You're subscribed!")
                    .foregroundColor(.green)
            } else {
                Button("Subscribe Now") {
                    startSubscription()
                }
                .buttonStyle(.borderedProminent)
            }

            if let error = errorMessage {
                Text("❌ \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .onAppear {
            checkSubscriptionStatus()
        }
    }

    private func checkSubscriptionStatus() {
        // Optional: Read from Firestore if you store subscription status
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                isSubscribed = data["isSubscribed"] as? Bool ?? false
            }
        }
    }

    private func startSubscription() {
        isLoading = true
        let functions = Functions.functions()
        let callable = functions.httpsCallable("startBusinessSubscription")

        callable.call(["priceId": priceId]) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                return
            }

            guard let data = result?.data as? [String: Any],
                  let clientSecret = data["clientSecret"] as? String else {
                self.errorMessage = "Invalid response from server"
                self.isLoading = false
                return
            }

            var config = PaymentSheet.Configuration()
            config.merchantDisplayName = "Your App Name"

            self.paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: config)

            presentPaymentSheet()
        }
    }

    private func presentPaymentSheet() {
        guard let paymentSheet = paymentSheet else { return }

        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first?.rootViewController else {
            self.errorMessage = "Unable to access root view controller"
            return
        }

        paymentSheet.present(from: rootVC) { result in
            isLoading = false
            switch result {
            case .completed:
                isSubscribed = true
                errorMessage = nil
            case .canceled:
                errorMessage = "Subscription cancelled"
            case .failed(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}
