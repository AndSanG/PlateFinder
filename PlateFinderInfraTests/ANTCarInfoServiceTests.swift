import Testing
import Foundation

@Suite struct ANTCarInfoServiceTests {

    @Test func init_doesNotRequestData() {
        let client = HTTPClientSpy()
        var sut: ANTCarInfoService? = ANTCarInfoService(url: anyURL(), client: client, mapper: CarHTMLMapperSpy())
        weak var weakSUT = sut

        #expect(client.requestedURLs.isEmpty)

        sut = nil
        #expect(weakSUT == nil, "Potential memory leak — ANTCarInfoService")
    }

    @Test func execute_requestsDataFromURL() async {
        let baseURL = URL(string: "https://a-base-url.com")!
        let (sut, client) = makeSUT(url: baseURL)

        _ = try? await sut.execute(plate: "ABC1234")

        let expectedURL = URL(string: "https://a-base-url.com?ps_tipo_identificacion=PLA&ps_identificacion=ABC1234&ps_placa=")!
        #expect(client.requestedURLs == [expectedURL])
    }

    @Test func execute_deliversNetworkErrorOnClientError() async {
        let (sut, client) = makeSUT()
        client.stubbedResult = .failure(NSError(domain: "any", code: 0))

        do {
            _ = try await sut.execute(plate: "ABC1234")
            Issue.record("Expected networkError, got no error")
        } catch let error as CarInfoError {
            #expect(error == .networkError(NSError(domain: "any", code: 0)))
        } catch {
            Issue.record("Expected CarInfoError.networkError, got \(error)")
        }
    }

    @Test(arguments: [199, 201, 300, 400, 500])
    func execute_deliversServerErrorOnNon200Response(statusCode: Int) async {
        let (sut, client) = makeSUT()
        client.stubbedResult = .success(makeHTTPResponse(statusCode: statusCode))

        do {
            _ = try await sut.execute(plate: "ABC1234")
            Issue.record("Expected serverError, got no error")
        } catch let error as CarInfoError {
            #expect(error == .serverError)
        } catch {
            Issue.record("Expected CarInfoError.serverError, got \(error)")
        }
    }

    @Test func execute_deliversParsingErrorOn200WhenMapperFails() async {
        let (sut, client) = makeSUT()
        client.stubbedResult = .success(makeHTTPResponse(statusCode: 200, data: Data("any html".utf8)))

        do {
            _ = try await sut.execute(plate: "ABC1234")
            Issue.record("Expected parsingError, got no error")
        } catch let error as CarInfoError {
            #expect(error == .parsingError(""))
        } catch {
            Issue.record("Expected CarInfoError.parsingError, got \(error)")
        }
    }

    @Test func execute_deliversCarOn200WithValidHTML() async throws {
        let expectedCar = makeCar()
        let mapper = CarHTMLMapperSpy(result: .success(expectedCar))
        let (sut, client) = makeSUT(mapper: mapper)
        client.stubbedResult = .success(makeHTTPResponse(statusCode: 200, data: Data("any html".utf8)))

        let car = try await sut.execute(plate: "ABC1234")

        #expect(car == expectedCar)
    }

    @Test func execute_doesNotLeakAfterAsyncOperationCompletes() async {
        let client = HTTPClientSpy()
        var sut: ANTCarInfoService? = ANTCarInfoService(url: anyURL(), client: client, mapper: CarHTMLMapperSpy())
        weak var weakSUT = sut

        _ = try? await sut!.execute(plate: "ABC1234")
        sut = nil

        #expect(weakSUT == nil, "Potential memory leak — ANTCarInfoService retained after async op")
    }

    // MARK: - Helpers

    private func makeSUT(
        url: URL = anyURL(),
        mapper: CarHTMLMapperSpy = CarHTMLMapperSpy()
    ) -> (sut: ANTCarInfoService, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = ANTCarInfoService(url: url, client: client, mapper: mapper)
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

private func makeHTTPResponse(
    statusCode: Int,
    data: Data = Data(),
    url: URL = URL(string: "https://a-url.com")!
) -> (Data, HTTPURLResponse) {
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

private final class CarHTMLMapperSpy: CarHTMLMapper {
    var result: Result<Car, Error>

    init(result: Result<Car, Error> = .failure(NSError(domain: "CarHTMLMapperSpy", code: 0))) {
        self.result = result
    }

    func map(_ html: String) throws -> Car {
        try result.get()
    }
}
