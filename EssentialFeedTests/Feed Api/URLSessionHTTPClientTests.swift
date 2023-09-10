//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Eric Ho on 9/5/23.
//

import XCTest
import Foundation
import EssentialFeed

class URLSessionHTTPClient {
    private let session:URLSession

    init(session:URLSession = .shared) {
        self.session = session
    }
    
    struct UnexpectedValuesRepresentation: Error {}
    
    func get(from url:URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, data.count > 0,  let response = response as? HTTPURLResponse {
                completion(.success(data, response))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequet()
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequet()
    }
    
    
    func test_getFromURL_performGETRequestWithURL() {
        let url = anyURL()
        
        let exp = expectation(description: "Wait for request")
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        makeSUT().get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnRequestError() {
        
        let requestError = anyNSError()
        let receivedError = resultForError(data: nil, response: nil, error: requestError)
        
        XCTAssertEqual((receivedError as NSError?)?.domain, requestError.domain)
        XCTAssertEqual((receivedError as NSError?)?.code, requestError.code)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(resultForError(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultForError(data: nil, response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultForError(data: nil, response: anyHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultForError(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultForError(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(resultForError(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultForError(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultForError(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultForError(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultForError(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    }
    
    func test_getFromURL_suceedsOnHTTPURLResponseWithData() {
        let data = anyData()
        let response = anyHTTPURLResponse()

        URLProtocolStub.stub(data: data, response: response, error: nil)

        let exp = expectation(description: "Wait for completion")
        makeSUT().get(from: anyURL()) { result in
            switch result {
            case .success(let receivedData, let receivedResponse):
                XCTAssertEqual(receivedData, data)
                XCTAssertEqual(receivedResponse.url, response.url)
                XCTAssertEqual(receivedResponse.statusCode, response.statusCode)
            default:
                XCTFail("Expected success, get \(result) instead")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    //MARKS: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeak(sut, file: file, line: line)
        return sut
    }
    
    
    func resultForError(data:Data?, response:URLResponse?, error:Error?, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        
        URLProtocolStub.stub(data: data, response: response, error:error)
        let sut = makeSUT(file:file, line:line)
        let exp = expectation(description: "Expected failure with error")
        
        var receievedError:Error?
        sut.get(from: anyURL()) { result in
            switch result {
            case .failure(let error):
                receievedError = error
            default:
                XCTFail("Expected failure, got \(result) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return receievedError
    }
    
    
    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
    
    private func anyData() -> Data {
        return Data(bytes: "any data".utf8)
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    private func nonHTTPURLResponse() -> URLResponse {
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private class URLProtocolStub: URLProtocol {
        
        private static var stub:Stub?
        private static var requestObserver: ((URLRequest) -> Void)?
        
        private struct Stub {
            let data:Data?
            let response:URLResponse?
            let error:Error?
        }
        
        static func stub(data: Data?, response:URLResponse?, error:Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func observeRequests(observer: @escaping (URLRequest) -> Void ) {
            requestObserver = observer
        }
        
        static func startInterceptingRequet() {
            URLProtocolStub.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequet() {
            URLProtocolStub.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {

            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
            
        }
        
        override func stopLoading() {
            
        }

    }
}
