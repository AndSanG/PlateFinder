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
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.plateNumber)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    if let car = item.car {
                        Text("\(car.manufacturer) \(car.model)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("no_information".localized)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .italic()
                    }

                    Text(item.relativeDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if item.car != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                        .accessibilityHidden(true)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
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
