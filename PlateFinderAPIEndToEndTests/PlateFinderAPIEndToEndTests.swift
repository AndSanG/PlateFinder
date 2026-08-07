import Testing
import Foundation
import SwiftSoup
import PlateFinderDomain

// Hits the live ANT endpoint. Requires network access.
// Serialized to avoid concurrent requests to the external API.
@Suite(.serialized)
struct PlateFinderAPIEndToEndTests {

    private let service: ANTCarInfoServiceE2E = {
        let baseURL = URL(string: "https://consultaweb.ant.gob.ec/PortalWEB/paginas/clientes/clp_grid_citaciones.jsp")!
        let client = URLSessionHTTPClientE2E(session: URLSession(configuration: .ephemeral))
        return ANTCarInfoServiceE2E(url: baseURL, client: client, mapper: ANTCarHTMLMapper())
    }()

    @Test func loadCarInfo_deliversValidCarForKnownPlate() async throws {
        // PBX0001 is used as a known ANT-registered plate.
        // If the test fails due to deregistration, replace with a current valid plate.
        let plate = "PBX0001"
        let car = try await service.execute(plate: plate)

        #expect(!car.plate.isEmpty, "Car.plate should not be empty")
        #expect(!car.manufacturer.isEmpty, "Car.manufacturer should not be empty")
        #expect(!car.model.isEmpty, "Car.model should not be empty")
    }

    @Test func loadCarInfo_deliversConnectivityErrorForUnreachableServer() async {
        let unreachableURL = URL(string: "https://0.0.0.0")!
        let client = URLSessionHTTPClientE2E(session: URLSession(configuration: .ephemeral))
        let sut = ANTCarInfoServiceE2E(url: unreachableURL, client: client, mapper: ANTCarHTMLMapper())

        do {
            _ = try await sut.execute(plate: "ABC1234")
            Issue.record("Expected connectivity error")
        } catch let error as CarInfoError {
            #expect(error == .networkError(NSError(domain: "any", code: 0)))
        } catch {
            Issue.record("Expected CarInfoError.networkError, got \(error)")
        }
    }
}

// MARK: - Inline production service (mirrors PlateFinder/Infrastructure/)

private final class URLSessionHTTPClientE2E: HTTPClient, Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, httpResponse)
    }
}

private final class ANTCarInfoServiceE2E: LoadCarInfo {
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

// MARK: - Inline production HTML mapper (SwiftSoup)

private final class ANTCarHTMLMapper: CarHTMLMapper {
    func map(_ html: String) throws -> Car {
        let document = try SwiftSoup.parse(html)
        guard let table = try document.select("body > table").first() else {
            throw CarInfoError.noDataFound
        }
        let rows = try table.select("tr")
        guard rows.count >= 4 else {
            throw CarInfoError.noDataFound
        }
        let r0 = try rows.get(0).select("td")
        let r1 = try rows.get(1).select("td")
        let r2 = try rows.get(2).select("td")
        let r3 = try rows.get(3).select("td")
        return Car(
            plate:              r0.safeText(at: 0),
            manufacturer:       r0.safeText(at: 2),
            colorName:          r0.safeText(at: 4),
            registrationYear:   r0.safeText(at: 6),
            model:              r1.safeText(at: 1),
            segment:            r1.safeText(at: 3),
            registrationDate:   r1.safeText(at: 5),
            year:               r2.safeText(at: 1),
            service:            r2.safeText(at: 3),
            expirationDate:     r2.safeText(at: 5),
            tint:               r3.safeText(at: 1),
            tintExpirationDate: r3.safeText(at: 3)
        )
    }
}

private extension Elements {
    func safeText(at index: Int) -> String {
        guard index < count else { return "" }
        return (try? get(index).text()) ?? ""
    }
}
