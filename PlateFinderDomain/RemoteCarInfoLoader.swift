import Foundation

public final class RemoteCarInfoLoader: CarInfoLoader {
    private let url: URL
    private let client: HTTPClient
    private let parser: HTMLParsing

    public init(url: URL, client: HTTPClient, parser: HTMLParsing) {
        self.url = url
        self.client = client
        self.parser = parser
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
            throw CarInfoError.networkError(error)
        }

        guard response.statusCode == 200 else {
            throw CarInfoError.serverError
        }

        guard let html = String(data: data, encoding: .isoLatin1) else {
            throw CarInfoError.parsingError("Failed to decode response as ISO Latin 1")
        }

        do {
            return try parser.parse(html)
        } catch {
            throw CarInfoError.parsingError(error.localizedDescription)
        }
    }
}
