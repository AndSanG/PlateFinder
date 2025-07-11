//
//  SearchHistoryItem.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 05/07/2025.
//

import Foundation

struct SearchHistoryItem: Codable, Identifiable, Equatable {
    let id = UUID()
    let plateNumber: String
    let searchDate: Date
    var car: Car? // Cache the car data if available
    
    private enum CodingKeys: String, CodingKey {
        case plateNumber, searchDate, car
    }
    
    init(plateNumber: String, searchDate: Date = Date(), car: Car? = nil) {
        self.plateNumber = plateNumber
        self.searchDate = searchDate
        self.car = car
    }
    
    static func == (lhs: SearchHistoryItem, rhs: SearchHistoryItem) -> Bool {
        return lhs.plateNumber == rhs.plateNumber
    }
}

extension SearchHistoryItem {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = LanguageManager.shared.currentLocale
        return formatter.string(from: searchDate)
    }
    
    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = LanguageManager.shared.currentLocale
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: searchDate, relativeTo: Date())
    }
}
