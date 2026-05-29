import Testing
import Foundation
@testable import PlateFinderDomain

// Tests run serially — URLProtocolStub uses static state.
@Suite(.serialized)
struct URLSessionHTTPClientTests {

    @Test func getFromURL_performsGETRequestWithURL() async {
        let url = URL(string: "https://a-url.com")!
        URLProtocolStub.stub(response: makeHTTPURLResponse(url: url, statusCode: 200))

        var capturedRequests: [URLRequest] = []
        URLProtocolStub.requestObserver = { capturedRequests.append($0) }
        defer { URLProtocolStub.requestObserver = nil }

        _ = try? await makeSUT().get(from: url)

        #expect(capturedRequests.count == 1)
        #expect(capturedRequests.first?.url == url)
        #expect(capturedRequests.first?.httpMethod == "GET")
    }

    @Test func getFromURL_deliversErrorOnRequestError() async {
        let expectedError = NSError(domain: "any-domain", code: 42)
        URLProtocolStub.stub(error: expectedError)

        do {
            _ = try await makeSUT().get(from: URL(string: "https://a-url.com")!)
            Issue.record("Expected error to be thrown")
        } catch let error as NSError {
            #expect(error.domain == expectedError.domain)
            #expect(error.code == expectedError.code)
        }
    }

    @Test func getFromURL_deliversDataAndResponseOnHTTPResponse() async throws {
        let url = URL(string: "https://a-url.com")!
        let expectedData = Data("any data".utf8)
        let expectedResponse = makeHTTPURLResponse(url: url, statusCode: 200)
        URLProtocolStub.stub(data: expectedData, response: expectedResponse)

        let (data, response) = try await makeSUT().get(from: url)

        #expect(data == expectedData)
        #expect(response.statusCode == expectedResponse.statusCode)
        #expect(response.url == url)
    }

    // MARK: - Helpers

    private func makeSUT() -> URLSessionHTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSessionHTTPClient(session: URLSession(configuration: configuration))
    }

    private func makeHTTPURLResponse(url: URL, statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}

// MARK: - URLProtocolStub

private class URLProtocolStub: URLProtocol {
    private struct Stub {
        let data: Data?
        let response: HTTPURLResponse?
        let error: Error?
    }

    private static var stub: Stub?
    static var requestObserver: ((URLRequest) -> Void)?

    static func stub(data: Data? = nil, response: HTTPURLResponse? = nil, error: Error? = nil) {
        stub = Stub(data: data, response: response, error: error)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        URLProtocolStub.requestObserver?(request)

        if let error = URLProtocolStub.stub?.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        if let data = URLProtocolStub.stub?.data {
            client?.urlProtocol(self, didLoad: data)
        }
        if let response = URLProtocolStub.stub?.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
