//
//  StripeManager.swift
//  lastminute
//
//  Created by Jabran Ali on 20/07/2025.
//

import StripePaymentsUI


class StripeManager {
    static let shared = StripeManager()
    
    private init() {}
    
    func setup() {
        // Use your Stripe publishable key here (replace with your actual test/live key)
        STPAPIClient.shared.publishableKey = "pk_test_your_publishable_key"
    }
}
