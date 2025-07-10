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
        HStack(spacing: 12) {
            // Star icon
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .font(.title3)
            
            // Plate number
            Text(plateNumber)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            // Action chevron
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .onTapGesture {
            onTap()
        }
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
