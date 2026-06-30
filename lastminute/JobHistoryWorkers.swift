//
//  JobHistoryWorkers.swift
//  lastminute
//
//  Created by Jabran Ali on 25/06/2025.
//

import SwiftUI

struct JobHistoryViewWorkers: View {
    @EnvironmentObject var jobStore: JobStore

    var body: some View {
        List {
            if jobStore.completedJobs.isEmpty {
                Text("No past jobs yet.")
                    .foregroundColor(.gray)
            } else {
                ForEach(jobStore.completedJobs) { job in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(job.title)
                            .font(.headline)

                        Text("Location: \(job.location)")
                            .font(.subheadline)

                        Text("Date: \(formattedDate(job.date)) at \(job.time)")
                            .font(.subheadline)

                        Text("Pay: \(job.pay)")
                            .font(.subheadline)

                        Text("Status: \(job.status.capitalized)")
                            .font(.footnote)
                            .foregroundColor(statusColor(job.status))
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Job History")
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "completed":
            return .green
        case "cancelled":
            return .red
        case "rejected":
            return .orange
        default:
            return .gray
        }
    }
}
