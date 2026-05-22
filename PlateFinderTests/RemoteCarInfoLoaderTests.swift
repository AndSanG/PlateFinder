import Testing
import Foundation
@testable import PlateFinder

@Suite struct RemoteCarInfoLoaderTests {

    @Test func init_doesNotRequestData() {
        let client = HTTPClientSpy()
        var sut: RemoteCarInfoLoader? = RemoteCarInfoLoader(url: anyURL(), client: client)
        weak var weakSUT = sut

        #expect(client.requestedURLs.isEmpty)

        sut = nil
        #expect(weakSUT == nil, "Potential memory leak — RemoteCarInfoLoader")
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = anyURL()) -> (sut: RemoteCarInfoLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteCarInfoLoader(url: url, client: client)
        return (sut, client)
    }
}

// MARK: - Shared helpers

private func anyURL() -> URL {
    URL(string: "https://a-url.com")!
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
