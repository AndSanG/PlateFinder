//
//  FavoriteItemView.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 05/07/2025.
//

import SwiftUI

struct FavoriteItemView: View {
    let plateNumber: String
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.title3)
                    .accessibilityHidden(true)

                Text(plateNumber)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemGray6))
            .clipShape(.rect(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("delete".localized, role: .destructive) {
                onDelete()
            }
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        FavoriteItemView(
            plateNumber: "ABC1234",
            onTap: {},
            onDelete: {}
        )
        
        FavoriteItemView(
            plateNumber: "XYZ5678",
            onTap: {},
            onDelete: {}
        )
    }
    .padding()
}
