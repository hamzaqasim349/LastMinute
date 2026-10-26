//
//  JobPaymentView.swift
//  lastminute
//
//  Shown to the business (customer) once a worker has completed a job,
//  letting them settle the job by cash or by card via Stripe PaymentSheet.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFunctions
import StripePaymentSheet

struct JobPaymentView: View {
    let job: Job
    /// Called when the customer closes the screen without paying (pay later).
    var onDismiss: () -> Void

    private enum Method {
        case cash
        case card
    }

    @State private var selectedMethod: Method? = nil
    @State private var isProcessing = false
    @State private var paymentSheet: PaymentSheet? = nil
    @State private var showPaymentSheet = false
    @State private var showCashConfirm = false
    @State private var statusPopup: StatusPopupData? = nil
    @State private var didPay = false

    private let accentBlue = Color(red: 0.2, green: 0.4, blue: 0.8)
    private let darkText = Color(red: 0.12, green: 0.15, blue: 0.3)
    private let background = Color(red: 0.92, green: 0.95, blue: 1.0)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    jobSummaryCard

                    VStack(alignment: .leading, spacing: 12) {
                        Text("How would you like to pay?")
                            .font(.headline)
                            .foregroundColor(darkText)

                        methodOption(
                            .cash,
                            icon: "banknote.fill",
                            title: "Cash",
                            subtitle: "Pay the worker directly in cash"
                        )

                        methodOption(
                            .card,
                            icon: "creditcard.fill",
                            title: "Card",
                            subtitle: "Pay securely with Stripe"
                        )
                    }

                    payButton
                }
                .padding(20)
            }
            .background(background.ignoresSafeArea())
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Later") { onDismiss() }
                        .disabled(isProcessing)
                }
            }
            .confirmationDialog(
                "Confirm cash payment",
                isPresented: $showCashConfirm,
                titleVisibility: .visible
            ) {
                Button("I've paid in cash") { recordPayment(method: "cash") }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Confirm that you have paid \(workerName) in cash for this job.")
            }
            .modifier(StripeSheetModifier(
                paymentSheet: paymentSheet,
                isPresented: $showPaymentSheet,
                onCompletion: handleCardResult
            ))
            .alert(
                statusPopup?.title ?? "",
                isPresented: Binding(
                    get: { statusPopup != nil },
                    set: { if !$0 { statusPopup = nil } }
                ),
                presenting: statusPopup
            ) { _ in
                Button("OK", role: .cancel) {
                    statusPopup = nil
                    // Close the payment screen once payment has been recorded
                    if didPay { onDismiss() }
                }
            } message: { popup in
                Text(popup.message)
            }
        }
        .interactiveDismissDisabled(isProcessing)
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text("Job Completed")
                .font(.title2.bold())
                .foregroundColor(darkText)

            Text("\(workerName) has finished the job. Please settle the payment.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var jobSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(job.title)
                .font(.headline)
                .foregroundColor(darkText)

            Label(job.location, systemImage: "mappin.circle.fill")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Label(job.time, systemImage: "clock")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()

            HStack {
                Text("Rate")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("£\(job.pay) /hr")
                    .font(.headline)
                    .foregroundColor(accentBlue)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private func methodOption(_ method: Method, icon: String, title: String, subtitle: String) -> some View {
        let isSelected = selectedMethod == method
        return Button {
            selectedMethod = method
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .white : accentBlue)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? accentBlue : accentBlue.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(darkText)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? accentBlue : .gray.opacity(0.5))
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? accentBlue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
    }

    private var payButton: some View {
        Button {
            switch selectedMethod {
            case .cash: showCashConfirm = true
            case .card: prepareCardPayment()
            case nil: break
            }
        } label: {
            HStack {
                if isProcessing {
                    ProgressView().tint(.white)
                } else {
                    Text(selectedMethod == .card ? "Pay with Card" : "Continue")
                        .bold()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(selectedMethod == nil ? Color.gray.opacity(0.4) : accentBlue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(selectedMethod == nil || isProcessing)
    }

    private var workerName: String {
        job.acceptedCandidate?.name ?? "The worker"
    }

    // MARK: - Card payment (Stripe)

    /// Asks the backend to create a PaymentIntent for this job, then presents Stripe's PaymentSheet.
    private func prepareCardPayment() {
        isProcessing = true

        Functions.functions().httpsCallable("preparePaymentSheet").call(["jobId": job.id]) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    isProcessing = false
                    statusPopup = StatusPopupData(kind: .error, title: "Payment Error", message: error.localizedDescription)
                    return
                }

                guard let data = result?.data as? [String: Any],
                      let clientSecret = data["paymentIntentClientSecret"] as? String,
                      let customerId = data["customer"] as? String,
                      let ephemeralKey = data["ephemeralKey"] as? String else {
                    isProcessing = false
                    statusPopup = StatusPopupData(kind: .error, title: "Payment Error", message: "Could not start the card payment. Please try again.")
                    return
                }

                var config = PaymentSheet.Configuration()
                config.merchantDisplayName = "LastMinute"
                config.customer = .init(id: customerId, ephemeralKeySecret: ephemeralKey)
                config.allowsDelayedPaymentMethods = false

                paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: config)
                showPaymentSheet = true
            }
        }
    }

    private func handleCardResult(_ result: PaymentSheetResult) {
        switch result {
        case .completed:
            recordPayment(method: "card")
        case .canceled:
            isProcessing = false
        case .failed(let error):
            isProcessing = false
            statusPopup = StatusPopupData(kind: .error, title: "Payment Failed", message: error.localizedDescription)
        }
    }

    // MARK: - Persist payment

    private func recordPayment(method: String) {
        isProcessing = true

        Firestore.firestore().collection("jobs").document(job.id).updateData([
            "paymentStatus": "paid",
            "paymentMethod": method,
            "paidAt": FieldValue.serverTimestamp()
        ]) { error in
            DispatchQueue.main.async {
                isProcessing = false
                if let error = error {
                    statusPopup = StatusPopupData(kind: .error, title: "Error", message: "Could not record payment: \(error.localizedDescription)")
                } else {
                    didPay = true
                    statusPopup = StatusPopupData(
                        kind: .success,
                        title: "Payment Complete",
                        message: method == "cash"
                            ? "Cash payment has been recorded. Thank you!"
                            : "Your card payment was successful. Thank you!"
                    )
                }
            }
        }
    }
}

/// Attaches Stripe's SwiftUI PaymentSheet presenter only once a PaymentSheet has been created.
private struct StripeSheetModifier: ViewModifier {
    let paymentSheet: PaymentSheet?
    @Binding var isPresented: Bool
    let onCompletion: (PaymentSheetResult) -> Void

    func body(content: Content) -> some View {
        if let paymentSheet {
            content.paymentSheet(isPresented: $isPresented, paymentSheet: paymentSheet, onCompletion: onCompletion)
        } else {
            content
        }
    }
}
