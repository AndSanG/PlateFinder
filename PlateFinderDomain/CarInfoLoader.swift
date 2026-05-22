import Foundation

public protocol HTTPClient {
    func get(from url: URL) async throws -> (Data, HTTPURLResponse)
}

public protocol CarInfoLoader {
    func loadCarInfo(for plateNumber: String) async throws -> Car
}

// Injected by the app target; implementation uses SwiftSoup (infrastructure).
public protocol HTMLParsing {
    func parse(_ html: String) throws -> Car
}
