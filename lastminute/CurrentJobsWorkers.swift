//
//  CurrentJobsWorkers.swift
//  lastminute
//
//  Created by Jabran Ali on 25/06/2025.
//

import SwiftUI
import FirebaseFirestore

struct CurrentJobsView: View {
    @EnvironmentObject var jobStore: JobStore
    
    // State to hold the job selected for completion
    @State private var selectedJob: Job? = nil
    @State private var enteredCode: String = ""
    @State private var showCodeEntry: Bool = false
    @State private var alertMessage: String? = nil
    
    var body: some View {
        NavigationView {
            List {
                ForEach(jobStore.activeJobs.filter { $0.status == "accepted" }) { job in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(job.title)
                            .font(.headline)
                        Text("\(job.location)")
                            .font(.subheadline)
                        Text(" \(job.time) on \(formattedDate(job.date))")
                            .font(.subheadline)
                        
                        Button("Enter Completion Code") {
                            selectedJob = job
                            enteredCode = ""
                            showCodeEntry = true
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 6)
                    }
                    .padding(.vertical, 8)
                }
                
                if jobStore.activeJobs.filter({ $0.status == "accepted" }).isEmpty {
                    Text("No accepted jobs yet.")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .navigationTitle("Current Jobs")
            .alert("Enter Completion Code", isPresented: $showCodeEntry, actions: {
                TextField("Code", text: $enteredCode)
                Button("Submit") {
                    verifyCode()
                }
                Button("Cancel", role: .cancel) {
                    selectedJob = nil
                    enteredCode = ""
                }
            }, message: {
                if let msg = alertMessage {
                    Text(msg)
                } else {
                    Text("Please enter the completion code provided by the business.")
                }
            })
        }
    }
    
    func verifyCode() {
        guard let job = selectedJob else { return }
        
        if enteredCode.uppercased() == job.completionCode?.uppercased() {
            // ✅ Correct code: update Firestore to mark job as completed
            let jobRef = Firestore.firestore().collection("jobs").document(job.id)
            
            jobRef.updateData(["status": "completed"]) { error in
                if let error = error {
                    alertMessage = "Error marking job complete: \(error.localizedDescription)"
                } else {
                    alertMessage = "Job marked as complete!"
                    // Optionally remove it from active jobs (to trigger UI refresh)
                    jobStore.workerActiveJobs.removeAll { $0.id == job.id }
                }
                showCodeEntry = true
            }
        } else {
            // ❌ Incorrect code
            alertMessage = "Incorrect completion code. Please try again."
            showCodeEntry = true
        }
    }
    
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

}
