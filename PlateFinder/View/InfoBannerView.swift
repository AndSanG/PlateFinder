//
//  InfoBannerView.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 03/07/2025.
//

import SwiftUI

struct InfoBannerView: View {
    let title: String
    let message: String
    @Binding var isShowing: Bool // Use a binding to control visibility from parent

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(.blue)
                .frame(width: 16)

            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.blue) 

                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    // Message
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true) // Allow text to wrap
                }

                Spacer()

                Button {
                    withAnimation {
                        isShowing = false
                    }
                } label: {
                    Image(systemName: "xmark") // Close icon
                        .font(.caption) // Smaller font for the close icon
                        .foregroundColor(.gray)
                        .padding(8) // Make touch target larger
                }
                .offset(x: 8, y: -8) // Adjust position of the close button slightly
            }
            .padding(.vertical, 12) // Vertical padding for the content
            .padding(.horizontal, 16) // Horizontal padding for the content
        }
        .cornerRadius(12) // Rounded corners for the banner
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white, lineWidth: 2)
        )
        .padding(.horizontal) // Padding from the screen edges
        .opacity(isShowing ? 1 : 0) // Control visibility
        .animation(.easeOut(duration: 0.3), value: isShowing) // Animate visibility changes
    }
}

// MARK: - Preview Provider

struct InfoBannerView_Previews: PreviewProvider {
    @State static var showBanner = true // State to control preview visibility

    static var previews: some View {
        VStack {
            Spacer()
            InfoBannerView(
                title: "Info",
                message: "New settings available on your account.",
                isShowing: $showBanner
            )
            Spacer()
            Button("Toggle Banner") {
                showBanner.toggle()
            }
            .buttonStyle(.bordered)
        }
        .background(Color.gray.opacity(0.1).ignoresSafeArea()) // Background for the preview
    }
}
