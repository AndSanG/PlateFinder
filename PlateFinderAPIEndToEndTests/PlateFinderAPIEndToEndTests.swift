import Testing
import Foundation
import SwiftSoup
@testable import PlateFinder

// Hits the live ANT endpoint. Requires network access.
// Serialized to avoid concurrent requests to the external API.
@Suite(.serialized)
struct PlateFinderAPIEndToEndTests {

    private let loader: RemoteCarInfoLoader = {
        let baseURL = URL(string: "https://consultaweb.ant.gob.ec/PortalWEB/paginas/clientes/clp_grid_citaciones.jsp")!
        let client = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
        return RemoteCarInfoLoader(url: baseURL, client: client, parser: ANTHTMLParser())
    }()

    @Test func loadCarInfo_deliversValidCarForKnownPlate() async throws {
        // PBX0001 is used as a known ANT-registered plate.
        // If the test fails due to deregistration, replace with a current valid plate.
        let plate = "PBX0001"
        let car = try await loader.loadCarInfo(for: plate)

        #expect(!car.plate.isEmpty, "Car.plate should not be empty")
        #expect(!car.manufacturer.isEmpty, "Car.manufacturer should not be empty")
        #expect(!car.model.isEmpty, "Car.model should not be empty")
    }

    @Test func loadCarInfo_deliversConnectivityErrorForUnreachableServer() async {
        let unreachableURL = URL(string: "https://0.0.0.0")!
        let client = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
        let sut = RemoteCarInfoLoader(url: unreachableURL, client: client, parser: ANTHTMLParser())

        do {
            _ = try await sut.loadCarInfo(for: "ABC1234")
            Issue.record("Expected connectivity error")
        } catch let error as CarInfoError {
            #expect(error == .connectivity)
        } catch {
            Issue.record("Expected CarInfoError.connectivity, got \(error)")
        }
    }
}

// MARK: - Inline production HTML parser (SwiftSoup; lives in infrastructure)

private final class ANTHTMLParser: HTMLParsing {
    func parse(_ html: String) throws -> Car {
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
            plate:            r0.safeText(at: 0),
            manufacturer:     r0.safeText(at: 2),
            colorName:        r0.safeText(at: 4),
            registrationYear: r0.safeText(at: 6),
            model:            r1.safeText(at: 1),
            segment:          r1.safeText(at: 3),
            registrationDate: r1.safeText(at: 5),
            year:             r2.safeText(at: 1),
            service:          r2.safeText(at: 3),
            expirationDate:   r2.safeText(at: 5),
            tint:             r3.safeText(at: 1),
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
