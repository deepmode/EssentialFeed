//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Eric Ho on 8/27/23.
//

import XCTest

import EssentialFeed

final class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url,url])
    }
    
    func test_load_deliversErrorOnClientError() {
        /*
        //note: Act -> Arrange -> Assert
        
        //Arrange: Given the sut and its HTTP client spy.
        let (sut, client) = makeSUT()
        
        //Act: When we tell the sut to load and we complete the client's HTTP request with an error.
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0) }
        
        let clientError = NSError(domain: "Test", code: 0)
        client.complete(with: clientError)
        
        //Assert: Then we expect the captured load error to be connectivity error.
        XCTAssertEqual(capturedErrors, [.connectivity])
        */
        
        let (sut, client) = makeSUT()
        expect(sut: sut, toCompleteWith: .failure(.connectivity)) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        }
    }
    
    
    func test_load_deliversErrorOn200HTTPResponse() {
        
        /*
        //note: Act -> Arrange -> Assert
        
        //Arrange: Given the sut and its HTTP client spy.
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, code in
            //Act: When we tell the sut to load and we complete the client's HTTP request with an error.
            var capturedErrors = [RemoteFeedLoader.Error]()
            sut.load {
                print("\(type(of:self)): \(#function)): sut.load")
                capturedErrors.append($0)
            }
            client.complete(withStatusCode: code, at: index)

            //Assert: Then we expect the captured load error to be connectivity
            XCTAssertEqual(capturedErrors,  [.invalidData])
        }
        */
        
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, code in
            expect(sut: sut, toCompleteWith: .failure(.invalidData)) {
                client.complete(withStatusCode: code, at: index)
            }
        }

    }
    
    func test_load_deleiversErrorOn200HTTPResponseWithInvalidJSON() {
        
        let (sut, client) = makeSUT()
        
        expect(sut: sut, toCompleteWith: .failure(.invalidData)) {
            let data = Data(#"Invaid Data"#.utf8)
            client.complete(withStatusCode: 200, data: data)
        }
    }
    
    func test_load_deleiversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()

        expect(sut: sut, toCompleteWith: .success([])) {
            let emptyListJSON = Data(#"{ "items": [] }"#.utf8)
            client.complete(withStatusCode: 200, data: emptyListJSON)
        }
        
        /*
        var capturedErrors = [RemoteFeedLoader.Result]()
        sut.load {
            capturedErrors.append($0)
        }
        
        let emptyListJSON = Data(#"{ "items": [] }"#.utf8)
        client.complete(withStatusCode: 200, data: emptyListJSON)
        XCTAssertEqual(capturedErrors, [.success([])])
        */
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
        let (sut, client) = makeSUT()
        
//        let item1 = FeedItem(id: UUID(), description: nil, location: nil, imageURL: URL(string:"https://a-url.com")!)
//
//        let item1JSON = [
//            "id": item1.id.uuidString,
//            "image": item1.imageURL.absoluteString
//        ]
//
//        let item2 = FeedItem(id: UUID(), description: "a description", location: "a location", imageURL: URL(string:"https://a-url.com")!)
//
//        let item2JSON = [
//            "id": item2.id.uuidString,
//            "description": item2.description,
//            "location": item2.location,
//            "image": item2.imageURL.absoluteString
//        ]
        
        let item1 = makeItem(id: UUID(), imageURL: URL(string:"https://a-url.com")!)
        let item2 = makeItem(id: UUID(), description: "a description", location: "a location", imageURL: URL(string:"https://a-url.com")!)
        
        let items = [item1.model, item2.model]
        
        expect(sut: sut, toCompleteWith: .success(items)) {
            let json = makeItemsJSON([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: json)
        }
    }
    
    //MARK: - Helpers
    private func makeSUT(url:URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client:HTTPClientSpy) {
        
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private func makeItem(id:UUID, description:String? = nil, location:String? = nil, imageURL:URL) -> (model:FeedItem, json:[String:Any]) {
        let feedItem = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].reduce(into: [String:Any]()) { acc, each in
            if let value = each.value {
                //accumulate only value is not nil
                acc[each.key] = value
            }
        }
        
        return (feedItem, json)
    }
    
    private func makeItemsJSON(_ items:[[String:Any]]) -> Data {
        let itemsJSON = ["items": items]
        let json = try! JSONSerialization.data(withJSONObject: itemsJSON)
        return json
    }
    
    private func expect(sut:RemoteFeedLoader, toCompleteWith result: RemoteFeedLoader.Result, whan action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load {
            capturedResults.append($0)
        }
        
        action() //action closure

        XCTAssertEqual(capturedResults, [result], file: file, line: line)
        
    }
    
    private class HTTPClientSpy: HTTPClient {
        
        var requestedURLs:[URL] {
            messages.map { $0.url }
        }
        
        var messages = [(url:URL, completion:(HTTPClientResult) -> Void)]()
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            print("\(type(of:self)): \(#function))")
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index:Int = 0) {
            print("\(type(of:self)): \(#function))")
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code:Int, data: Data = Data(), at index:Int = 0) {
            print("\(type(of:self)): \(#function))")
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil)!
            
            messages[index].completion(.success(data, response))
        }
    }
    
    
    
    /*
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
    */

}
