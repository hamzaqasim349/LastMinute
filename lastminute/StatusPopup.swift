//
//  StatusPopup.swift
//  lastminute
//
//  Created by Hamza Qasim on 30/06/2026.
//

import SwiftUI

enum StatusKind {
    case success
    case error
    case info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return Color(red: 0.2, green: 0.4, blue: 0.8)
        }
    }
}

struct StatusPopupData: Equatable {
    var kind: StatusKind
    var title: String
    var message: String
}

struct StatusPopupView: View {
    let data: StatusPopupData
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.05)
                .ignoresSafeArea()

            // Native-style alert card with colored icon
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Image(systemName: data.kind.icon)
                        .font(.system(size: 32))
                        .foregroundColor(data.kind.color)
                        .scaleEffect(appeared ? 1.0 : 0.6)

                    Text(data.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    Text(data.message)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 14)

                Divider()

                Button {
                    onDismiss()
                } label: {
                    Text("OK")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(data.kind.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
            .frame(width: 320)
            .background(
                // Frosted, semi-transparent card tinted with the app's blue theme
                ZStack {
                    Color(red: 0.92, green: 0.95, blue: 1.0).opacity(0.75)
                    Rectangle().fill(.ultraThinMaterial)
                }
            )
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: Color(red: 0.2, green: 0.4, blue: 0.8).opacity(0.15), radius: 20, x: 0, y: 10)
            .scaleEffect(appeared ? 1.0 : 1.12)
            .opacity(appeared ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.2)) {
                appeared = true
            }
        }
    }
}

// MARK: - View Modifier for easy use

extension View {
    /// Presents a native iOS system alert (matching the standard dialog look)
    /// for the given status data. Clears the binding when dismissed.
    func statusPopup(_ data: Binding<StatusPopupData?>) -> some View {
        self.alert(
            data.wrappedValue?.title ?? "",
            isPresented: Binding(
                get: { data.wrappedValue != nil },
                set: { if !$0 { data.wrappedValue = nil } }
            ),
            presenting: data.wrappedValue
        ) { _ in
            Button("OK", role: .cancel) {
                data.wrappedValue = nil
            }
        } message: { popup in
            Text(popup.message)
        }
    }
}
