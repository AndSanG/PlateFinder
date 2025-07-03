//
//  CarDetail.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 03/07/2025.
//

import SwiftUI

struct CarDetailItem: View {
    let title: String
    let subtitle: String
    let iconName: String

    var body: some View {
        HStack(spacing: 32) {
            Image(systemName: iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(subtitle)
                    .font(.headline)
                    .bold()
                Text(title)
                    .font(.body)
            }
        }
        .padding(10)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview Provider

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        CarDetailItem(title: "Susan Sunshine", subtitle: "summer@example.com", iconName: "person.circle")
            .previewLayout(.sizeThatFits) // Makes the preview fit the content
            .padding() // Add padding around the preview itself
    }
}
