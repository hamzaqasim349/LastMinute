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
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Card
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(data.kind.color.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(systemName: data.kind.icon)
                        .font(.system(size: 44))
                        .foregroundColor(data.kind.color)
                        .scaleEffect(appeared ? 1.0 : 0.5)
                        .opacity(appeared ? 1.0 : 0.0)
                }

                Text(data.title)
                    .font(.title3.bold())
                    .foregroundColor(Color(red: 0.12, green: 0.15, blue: 0.3))
                    .multilineTextAlignment(.center)

                Text(data.message)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                Button {
                    onDismiss()
                } label: {
                    Text("Done")
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(data.kind.color)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.top, 4)
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 40)
            .scaleEffect(appeared ? 1.0 : 0.85)
            .opacity(appeared ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}

// MARK: - View Modifier for easy use

extension View {
    func statusPopup(_ data: Binding<StatusPopupData?>) -> some View {
        self.overlay {
            if let popup = data.wrappedValue {
                StatusPopupView(data: popup) {
                    withAnimation {
                        data.wrappedValue = nil
                    }
                }
                .transition(.opacity)
            }
        }
    }
}
