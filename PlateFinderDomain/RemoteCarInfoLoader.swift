import Foundation

public final class RemoteCarInfoLoader: CarInfoLoader {
    private let url: URL
    private let client: HTTPClient

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func loadCarInfo(for plateNumber: String) async throws -> Car {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "ps_tipo_identificacion", value: "PLA"),
            URLQueryItem(name: "ps_identificacion", value: plateNumber),
            URLQueryItem(name: "ps_placa", value: "")
        ]
        do {
            _ = try await client.get(from: components.url!)
        } catch {
            throw CarInfoError.connectivity
        }
        fatalError("mapping not implemented")
    }
}
