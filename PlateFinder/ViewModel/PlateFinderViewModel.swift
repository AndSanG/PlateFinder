//
//  PlateFinderViewModel.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 01/07/2025.
//

import Foundation
import SwiftSoup

enum State {
    case idle
    case loading
    case loaded(car: Car)
    case error(Error)
}

@MainActor
class PlateFinderViewModel: ObservableObject{
    @Published var plateNumber: String = ""
    @Published var isTesting = true
    @Published var state: State = .idle
    
    let service = CarInfoService()
    
    
    func getCarInfo() async {
        
        self.state = .loading
        
        do {
            let car = try await service.getCarInfo( with: plateNumber, isTesting: isTesting)
            self.state = .loaded(car: car)
        } catch let error as CarInfoError {
            print("A specific error occurred: \(error.localizedDescription)")
            self.state = .error(error)
        } catch {
            self.state = .error(error)
            print("An unexpected error occurred: \(error.localizedDescription)")
        }
    }
}
