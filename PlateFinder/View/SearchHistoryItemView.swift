//
//  SearchHistoryItemView.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 05/07/2025.
//

import SwiftUI

struct SearchHistoryItemView: View {
    let item: SearchHistoryItem
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Plate number and car info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.plateNumber)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let car = item.car {
                    Text("\(car.manufacturer) \(car.model)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("no_information".localized)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .italic()
                }
                
                Text(item.relativeDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status indicator
            if item.car != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
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
    VStack(spacing: 20) {
        SearchHistoryItemView(
            item: SearchHistoryItem(
                plateNumber: "ABC1234",
                searchDate: Date(),
                car: Car.mock
            ),
            onTap: {},
            onDelete: {}
        )
        
        SearchHistoryItemView(
            item: SearchHistoryItem(
                plateNumber: "XYZ5678",
                searchDate: Date(),
                car: nil
            ),
            onTap: {},
            onDelete: {}
        )
    }
    .padding()
}
