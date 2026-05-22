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
        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await client.get(from: components.url!)
        } catch {
            throw CarInfoError.connectivity
        }

        guard response.statusCode == 200 else {
            throw CarInfoError.invalidData
        }

        fatalError("mapping not implemented")
    }
}
