//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Eric Ho on 29/1/2023.
//

import XCTest

//note: can do "@testable import EssentialFeed" (not a prefer way instead ...
//note: a better a apporach, when possible, is to test the module through the public interfaces (via public class, public method, public protocol etc), so we can test the expected behavior as a client of the module. Another Benefit: we're free to change internal and private implmentation details without breaking the tests.
import EssentialFeed


final class RemoteFeedLoaderTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    //note: test (test), init (the method), doesNotRequestDataFromURL (the behaviors we are tested)
    func test_init_doesNotRequestDataFromURL() {
        
        //note: some kind of client to handle network call or requesting data from url
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        
        //Arrange
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        //note: 3 types of injection
        //1. constructor injection e.g. RemoteFeedLoader(client: XXX)
        //2. property injection e.g. sut.client = XXX
        //3. method injection e.g. sut.load(client: XXX)
        
        //Act
        //note: When testing objects collaborating, asserting the values passwd is not enough. We also need to ask "How many times was the method invoked?"
        sut.load { _ in }
        
        //Assert
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURL() {
        
        //Arrange
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        //Act
        //note: When testing objects collaborating, asserting the values passwd is not enough. We also need to ask "How many times was the method invoked?"
        sut.load { _ in }
        sut.load { _ in }
        
        //Assert
        //note: assrt equality, counts at once
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        
        //note: Arrange: Given the sut and its HTTP client spy.
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(.connectivity), when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        let samples = [199, 201, 300, 400, 500]
        
        
        samples.enumerated().forEach { (index, code) in
            expect(sut, toCompleteWith: .failure(.invalidData), when: {
                let json = makeItemsJSON([])
                client.complete(withStatusCode: code, data: json, at: index)
            })
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponse() {
        
        //1. Arrange
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(.invalidData), when: {
            let jsonData = Data("Invalid json".utf8)
            client.complete(withStatusCode: 200, data: jsonData )
        })
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithJSONList() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .success([]), when: {
            //let emptyJsonData = Data("{\"items\": []}".utf8)
            //let emptyJsonData = Data(#"{"items": []}"#.utf8)
            let emptyJsonData = makeItemsJSON([])
            client.complete(withStatusCode: 200, data: emptyJsonData, at: 0)
        })
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithJSONList() {
        let (sut, client) = makeSUT()
        
        //note: testing the JSON items return from 200 http response and map to   -> [FeedItem]
        
        let item1 =  makeItem(id:UUID(),
                              description: nil,
                              location: nil,
                              imageURL: URL(string:"http://a-url.com")!)
        
        
        
        let item2 =  makeItem(id:UUID(),
                              description: "a description",
                              location: "a location",
                              imageURL: URL(string:"http://another-url.com")!)
        
        
        
        //note: create a json object to mock the server JSON response
        let items = [item1.model, item2.model]
        
        expect(sut, toCompleteWith: .success(items), when: {
            
            let json = makeItemsJSON([item1.json, item2.json])
            
            client.complete(withStatusCode: 200, data: json)
            
        })
    }
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        
        trackForMemoryLeaks(sut, file:file, line: line)
        trackForMemoryLeaks(client, file:file, line: line)
        return (sut,client)
    }
    
    private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been dellocated. Potential memory leak.", file: file, line:line)
            
        }
    }
    
    func makeItem(id:UUID, description:String? = nil, location:String? = nil, imageURL:URL) -> (model:FeedItem, json:[String:Any]) {
        let item = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        
//        let json:[String: Any] = [
//            "id": id.uuidString,
//            "description": description,
//            "location": location,
//            "image": imageURL.absoluteString
//        ].reduce(into: [String:Any]()) { acc, e in
//            if let value = e.value {
//                acc[e.key] = value
//            }
//        }
        
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].compactMapValues { each in
            each
        }
        
        return (item, json)
    }
    
    private func makeItemsJSON(_ items:[[String : Any]]) -> Data {
        let json = ["items":items]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    //note: Using result type (RemoteFeedLoader.Result) enable resuability for different potential results in the future
    private func expect(_ sut:RemoteFeedLoader, toCompleteWith result:RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        
        //2. Act
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load {
            capturedResults.append($0)
        }
        action()
        
        //3. Assert
        XCTAssertEqual(capturedResults, [result], file: file, line: line)
    }
    

    class HTTPClientSpy: HTTPClient {
        
        private var messages = [(url:URL, completion:(HTTPClientResult) -> Void)]()
        
        var requestedURLs:[URL] {
           messages.map { $0.url }
            //messages.map { (url, completion) in url }
        }
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            
            //note: just capture the message (url, completion, etc)
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index:Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data, at index:Int = 0) {
            
            let response = HTTPURLResponse(url: messages[index].url, statusCode: code, httpVersion: nil, headerFields: nil)!
            
            //note: execute the completion (capture in get(from:completion:) method call) with data at index position
            messages[index].completion(.success(data, response))
        }
    }

}

