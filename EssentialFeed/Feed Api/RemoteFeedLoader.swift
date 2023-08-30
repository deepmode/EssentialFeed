//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Eric Ho on 8/28/23.
//

import Foundation

public enum HTTPClientResult {
    case success(HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}

public final class RemoteFeedLoader {
    
    private let url:URL
    private let client:HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public init(url:URL, client:HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (Error) -> Void) {
        print("\n\(type(of:self)): \(#function))")
        client.get(from: url) { result in
            //domain specific error
            print("\(type(of:self)): \(#function)) result")
            switch result {
            case .success(_):
                completion(.invalidData)
            case .failure(_):
                completion(.connectivity)
            }
        }
    }
}


