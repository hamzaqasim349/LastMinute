//
//  Businessprofileviewmodel.swift
//  lastminute
//
//  Created by Jabran Ali on 17/11/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class BusinessProfileViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var phone = ""
    @Published var address = ""
    @Published var description = ""

    private let db = Firestore.firestore()
    private var originalData = [String: Any]()

    var hasChanges: Bool {
        return name != (originalData["name"] as? String ?? "") ||
               email != (originalData["email"] as? String ?? "") ||
               phone != (originalData["phone"] as? String ?? "") ||
               address != (originalData["address"] as? String ?? "") ||
               description != (originalData["description"] as? String ?? "")
    }

    // Load profile from Firestore
    func load() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("businesses").document(uid).getDocument { snapshot, _ in
            guard let data = snapshot?.data() else { return }

            self.originalData = data
            self.name = data["name"] as? String ?? ""
            self.email = data["email"] as? String ?? ""
            self.phone = data["phone"] as? String ?? ""
            self.address = data["address"] as? String ?? ""
            self.description = data["description"] as? String ?? ""
        }
    }

    // Save profile changes
    func save() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let updatedData: [String: Any] = [
            "name": name,
            "email": email,
            "phone": phone,
            "address": address,
            "description": description
        ]

        db.collection("businesses").document(uid).setData(updatedData, merge: true)
    }
}
