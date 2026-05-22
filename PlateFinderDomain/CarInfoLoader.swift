import Foundation

public protocol HTTPClient {
    func get(from url: URL) async throws -> (Data, HTTPURLResponse)
}

public protocol CarInfoLoader {
    func loadCarInfo(for plateNumber: String) async throws -> Car
}
