import Foundation

public protocol HTTPClient: Sendable {
    func get(from url: URL) async throws -> (Data, HTTPURLResponse)
}

public protocol LoadCarInfo: Sendable {
    func execute(plate: String) async throws -> Car
}

public protocol CarHTMLMapper: Sendable {
    func map(_ html: String) throws -> Car
}
