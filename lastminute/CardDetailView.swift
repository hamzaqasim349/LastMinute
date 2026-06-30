//
//  CardDetailView.swift
//  lastminute
//
//  Created by Jabran Ali on 20/07/2025.
//
import SwiftUI

struct CardDetailsView: View {
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvc = ""
    @State private var nameOnCard = ""

    var onSubmit: ((CardInfo) -> Void)?  // A callback to send data back
    
    var body: some View {
        Form {
            TextField("Card Number", text: $cardNumber)
                .keyboardType(.numberPad)
            TextField("Expiry Date (MM/YY)", text: $expiryDate)
            TextField("CVC", text: $cvc)
                .keyboardType(.numberPad)
            TextField("Name on Card", text: $nameOnCard)
            
            Button("Save Card") {
                let cardInfo = CardInfo(number: cardNumber, expiry: expiryDate, cvc: cvc, name: nameOnCard)
                onSubmit?(cardInfo)
            }
            .disabled(cardNumber.isEmpty || expiryDate.isEmpty || cvc.isEmpty || nameOnCard.isEmpty)
        }
    }
}

struct CardInfo {
    let number: String
    let expiry: String
    let cvc: String
    let name: String
}
