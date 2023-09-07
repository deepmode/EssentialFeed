//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Eric Ho on 9/5/23.
//

import XCTest
import Foundation
import EssentialFeed

protocol HTTPSession {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSsessionTask
}

protocol HTTPSsessionTask {
    func resume()
}

class URLSessionHTTPClient {
    private let session:HTTPSession

    init(session:HTTPSession) {
        self.session = session
    }
    
    func get(from url:URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    
    func test_getFromURL_resumeDataTaskWithURL() {
        let url = URL(string: "https://any-url.com/")!
        let session = URLSessionSpy()
        let task = URLSessionDataTaskSpy()
        let sut = URLSessionHTTPClient(session: session)
        session.stubs(url: url, task: task)
        
        sut.get(from: url) { _ in }
        
        XCTAssertEqual(task.resumeCallCount, 1)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "https://any-url.com/")!
        let error = NSError(domain: "any error", code: 1)
        let session = URLSessionSpy()
        session.stubs(url: url, error:error)
    
        let sut = URLSessionHTTPClient(session: session)
    
        let exp = expectation(description: "Expected failure with error")
        
        sut.get(from: url) { result in
            switch result {
            case let .failure(receivedError as NSError):
                XCTAssertEqual(receivedError, error)
            default:
                XCTFail("Expected failure with error \(error), get \(result) instead")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    //MARKS: - Helpers
    
    private class URLSessionSpy: HTTPSession {
        
        private var stubs = [URL:Stub]()
        
        private struct Stub {
            let task:HTTPSsessionTask
            let error:Error?
        }
        
        func stubs(url:URL, task:HTTPSsessionTask = FakeURLSessionDataTask(), error:Error? = nil) {
            stubs[url] = Stub(task: task, error: error)
        }
        
        func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSsessionTask {
            
            guard let stub = stubs[url] else {
                fatalError("Couldn't find stub for \(url)")
            }

            completionHandler(nil, nil, stub.error)
            
            return  stub.task
        }
    }
    
    private class FakeURLSessionDataTask: HTTPSsessionTask {
        func resume() {
        }
    }
    
    private class URLSessionDataTaskSpy: HTTPSsessionTask {
        var resumeCallCount = 0
        
        func resume() {
            resumeCallCount += 1
        }
    }
    
    

//    override func setUpWithError() throws {
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//
//        // In UI tests it is usually best to stop immediately when a failure occurs.
//        continueAfterFailure = false
//
//        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
//    }
//
//    override func tearDownWithError() throws {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }
//
//    func testExample() throws {
//        // UI tests must launch the application that they test.
//        let app = XCUIApplication()
//        app.launch()
//
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//    }
//
//    func testLaunchPerformance() throws {
//        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
//            // This measures how long it takes to launch your application.
//            measure(metrics: [XCTApplicationLaunchMetric()]) {
//                XCUIApplication().launch()
//            }
//        }
//    }
}
