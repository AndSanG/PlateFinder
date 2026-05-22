import Foundation

public final class RemoteCarInfoLoader: CarInfoLoader {
    private let url: URL
    private let client: HTTPClient

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func loadCarInfo(for plateNumber: String) async throws -> Car {
        fatalError("loadCarInfo(for:) not implemented")
    }
}
