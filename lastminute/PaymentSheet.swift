//
//  PaymentSheet.swift
//  lastminute
//
//  Created by Jabran Ali on 20/07/2025.
//

import SwiftUI
import StripePaymentSheet
import FirebaseFunctions
import UIKit

struct PaymentView: View {
    @State private var paymentSheet: PaymentSheet?
    @State private var paymentResult: PaymentSheetResult?
    @State private var loading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            if loading {
                ProgressView("Preparing payment sheet...")
            } else {
                Button("Pay or Add Card") {
                    startPayment()
                }
                .buttonStyle(.borderedProminent)
            }

            if let result = paymentResult {
                switch result {
                case .completed:
                    Text("✅ Payment complete!")
                        .foregroundColor(.green)
                case .canceled:
                    Text("Payment canceled.")
                case .failed(let error):
                    Text("❌ Payment failed: \(error.localizedDescription)")
                        .foregroundColor(.red)
                }
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .onAppear {
            preparePaymentSheet()
        }
    }

    func preparePaymentSheet() {
        loading = true

        let functions = Functions.functions()
        functions.httpsCallable("preparePaymentSheet").call { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.loading = false
                return
            }

            guard let data = result?.data as? [String: Any],
                  let clientSecret = data["paymentIntentClientSecret"] as? String,
                  let customerId = data["customer"] as? String,
                  let ephemeralKey = data["ephemeralKey"] as? String else {
                self.errorMessage = "❌ Failed to parse backend response"
                self.loading = false
                return
            }

            var config = PaymentSheet.Configuration()
            config.merchantDisplayName = "Your Business Name"
            config.customer = .init(id: customerId, ephemeralKeySecret: ephemeralKey)
            config.allowsDelayedPaymentMethods = true

            self.paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: config)
            self.loading = false
        }
    }

    func startPayment() {
        guard let paymentSheet = paymentSheet else { return }
        loading = true

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            self.errorMessage = "Could not find root view controller"
            self.loading = false
            return
        }

        paymentSheet.present(from: rootVC) { result in
            loading = false
            self.paymentResult = result
        }
    }
}
