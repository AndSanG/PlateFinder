import Foundation

final class ANTCarInfoService: LoadCarInfo {
    private let url: URL
    private let client: any HTTPClient
    private let mapper: any CarHTMLMapper

    init(url: URL, client: any HTTPClient, mapper: any CarHTMLMapper) {
        self.url = url
        self.client = client
        self.mapper = mapper
    }

    func execute(plate: String) async throws -> Car {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "ps_tipo_identificacion", value: "PLA"),
            URLQueryItem(name: "ps_identificacion", value: plate),
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
            return try mapper.map(html)
        } catch {
            throw CarInfoError.parsingError(error.localizedDescription)
        }
    }
}
