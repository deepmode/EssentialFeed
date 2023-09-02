//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Eric Ho on 8/28/23.
//

import Foundation

public final class RemoteFeedLoader {
    
    private let url:URL
    private let client:HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public enum Result: Equatable {        
        case success([FeedItem])
        case failure(Error)
    }
    
    public init(url:URL, client:HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        print("\n\(type(of:self)): \(#function))")
        client.get(from: url) { result in
            //domain specific error
            //print("\(type(of:self)): \(#function)) result")
            switch result {
            case .success(let data, let response):
                do {
                    let items = try FeedItemsMapper.map(data, response)
                    completion(.success(items))
                } catch {
                    completion(.failure(.invalidData))
                }
            case .failure(_):
                completion(.failure(.connectivity))
            }
        }
    }
}


