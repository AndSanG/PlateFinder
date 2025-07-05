//
//  PlateFinderViewModel.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 01/07/2025.
//

import Foundation
import SwiftSoup

enum Stage {
    case idle
    case loading
    case loaded(car: Car)
    case error(Error)
}

@MainActor
class PlateFinderViewModel: ObservableObject{
    @Published var plateNumber: String = ""
    @Published var isTesting = true
    @Published var stage: Stage = .idle
    
    let service = CarInfoService()
    
    
    func getCarInfo() async {
        
        self.stage = .loading
        
        do {
            let car = try await service.getCarInfo( with: plateNumber, isTesting: isTesting)
            self.stage = .loaded(car: car)
        } catch let error as CarInfoError {
            print("A specific error occurred: \(error.localizedDescription)")
            self.stage = .error(error)
        } catch {
            self.stage = .error(error)
            print("An unexpected error occurred: \(error.localizedDescription)")
        }
    }
}
