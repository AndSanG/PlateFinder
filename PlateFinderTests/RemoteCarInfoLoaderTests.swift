import Testing
import Foundation
@testable import PlateFinder

@Suite struct RemoteCarInfoLoaderTests {

    @Test func init_doesNotRequestData() {
        let client = HTTPClientSpy()
        var sut: RemoteCarInfoLoader? = RemoteCarInfoLoader(url: anyURL(), client: client, parser: HTMLParsingSpy())
        weak var weakSUT = sut

        #expect(client.requestedURLs.isEmpty)

        sut = nil
        #expect(weakSUT == nil, "Potential memory leak — RemoteCarInfoLoader")
    }

    @Test func load_requestsDataFromURL() async {
        let baseURL = URL(string: "https://a-base-url.com")!
        let (sut, client) = makeSUT(url: baseURL)

        _ = try? await sut.loadCarInfo(for: "ABC1234")

        let expectedURL = URL(string: "https://a-base-url.com?ps_tipo_identificacion=PLA&ps_identificacion=ABC1234&ps_placa=")!
        #expect(client.requestedURLs == [expectedURL])
    }

    @Test func load_deliversConnectivityErrorOnClientError() async {
        let (sut, client) = makeSUT()
        client.stubbedResult = .failure(NSError(domain: "any", code: 0))

        do {
            _ = try await sut.loadCarInfo(for: "ABC1234")
            Issue.record("Expected connectivity error, got no error")
        } catch let error as CarInfoError {
            #expect(error == .connectivity)
        } catch {
            Issue.record("Expected CarInfoError.connectivity, got \(error)")
        }
    }

    @Test(arguments: [199, 201, 300, 400, 500])
    func load_deliversInvalidDataErrorOnNon200Response(statusCode: Int) async {
        let (sut, client) = makeSUT()
        client.stubbedResult = .success(makeHTTPResponse(statusCode: statusCode))

        do {
            _ = try await sut.loadCarInfo(for: "ABC1234")
            Issue.record("Expected invalidData error, got no error")
        } catch let error as CarInfoError {
            #expect(error == .invalidData)
        } catch {
            Issue.record("Expected CarInfoError.invalidData, got \(error)")
        }
    }

    @Test func load_deliversInvalidDataErrorOn200WithInvalidHTML() async {
        let (sut, client) = makeSUT()
        client.stubbedResult = .success(makeHTTPResponse(statusCode: 200, data: Data("invalid html".utf8)))

        do {
            _ = try await sut.loadCarInfo(for: "ABC1234")
            Issue.record("Expected invalidData error, got no error")
        } catch let error as CarInfoError {
            #expect(error == .invalidData)
        } catch {
            Issue.record("Expected CarInfoError.invalidData, got \(error)")
        }
    }

    @Test func load_deliversCarOn200WithValidHTML() async throws {
        let expectedCar = makeCar()
        let parser = HTMLParsingSpy(result: .success(expectedCar))
        let (sut, client) = makeSUT(parser: parser)
        client.stubbedResult = .success(makeHTTPResponse(statusCode: 200, data: Data("any html".utf8)))

        let car = try await sut.loadCarInfo(for: "ABC1234")

        #expect(car == expectedCar)
    }

    // MARK: - Helpers

    private func makeSUT(
        url: URL = anyURL(),
        parser: HTMLParsing = HTMLParsingSpy()
    ) -> (sut: RemoteCarInfoLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteCarInfoLoader(url: url, client: client, parser: parser)
        return (sut, client)
    }

    private func makeCar() -> Car {
        Car(
            plate: "ABC1234", manufacturer: "TOYOTA", colorName: "WHITE",
            registrationYear: "2020", model: "COROLLA", segment: "SEDAN",
            registrationDate: "01-01-2020", year: "2019", service: "PRIVATE",
            expirationDate: "01-01-2025", tint: "NONE", tintExpirationDate: ""
        )
    }
}

// MARK: - Shared helpers

private func anyURL() -> URL {
    URL(string: "https://a-url.com")!
}

private func makeHTTPResponse(statusCode: Int, data: Data = Data(), url: URL = URL(string: "https://a-url.com")!) -> (Data, HTTPURLResponse) {
    let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    return (data, response)
}

// MARK: - Test Doubles

private final class HTTPClientSpy: HTTPClient {
    private(set) var requestedURLs: [URL] = []
    var stubbedResult: Result<(Data, HTTPURLResponse), Error> =
        .failure(NSError(domain: "HTTPClientSpy", code: 0))

    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        requestedURLs.append(url)
        return try stubbedResult.get()
    }
}

private final class HTMLParsingSpy: HTMLParsing {
    var result: Result<Car, Error>

    init(result: Result<Car, Error> = .failure(NSError(domain: "HTMLParsingSpy", code: 0))) {
        self.result = result
    }

    func parse(_ html: String) throws -> Car {
        try result.get()
    }
}
