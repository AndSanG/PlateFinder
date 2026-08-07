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
                    .foregroundStyle(.blue)
                    .accessibilityHidden(true) 

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button {
                    withAnimation {
                        isShowing = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .padding(8)
                }
                .accessibilityLabel("dismiss".localized)
                .offset(x: 8, y: -8)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white, lineWidth: 2)
        )
        .padding(.horizontal)
        .opacity(isShowing ? 1 : 0)
        .animation(.easeOut(duration: 0.3), value: isShowing)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview Provider

struct InfoBannerView_Previews: PreviewProvider {
    @State static var showBanner = true // State to control preview visibility

    static var previews: some View {
        VStack {
            Spacer()
            InfoBannerView(
                title: "important".localized,
                message: "enter_plate_without_dash".localized,
                isShowing: $showBanner
            )
            Spacer()
            Button("toggle_banner".localized) {
                showBanner.toggle()
            }
            .buttonStyle(.bordered)
        }
        .background(Color.gray.opacity(0.1).ignoresSafeArea()) // Background for the preview
    }
}
