//
//  JobHistoryView.swift
//  lastminute
//
//  Created by Jabran Ali on 22/06/2025.
//

import SwiftUI

struct JobHistoryView: View {
    @EnvironmentObject var jobStore: JobStore
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        List {
            if !jobStore.completedJobs.isEmpty {
                Section(header: Text("Completed Jobs")) {
                    ForEach(jobStore.completedJobs) { job in
                        VStack(alignment: .leading) {
                            Text(job.title).font(.headline)
                            Text("Completed on: \(formattedDate(job.date))").font(.caption)
                        }
                    }
                }
            }

            if !jobStore.deletedJobs.isEmpty {
                Section(header: Text("Deleted Jobs")) {
                    ForEach(jobStore.deletedJobs) { job in
                        VStack(alignment: .leading) {
                            Text(job.title).font(.headline)
                            Text("Deleted on: \(formattedDate(Date()))").font(.caption) // current date since no timestamp stored
                        }
                    }
                }
            }

            if jobStore.completedJobs.isEmpty && jobStore.deletedJobs.isEmpty {
                Text("No job history available.")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .navigationTitle("Job History")
        .listStyle(GroupedListStyle())
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
