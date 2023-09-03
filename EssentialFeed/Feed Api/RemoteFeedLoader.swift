//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Eric Ho on 8/28/23.
//

import Foundation

public final class RemoteFeedLoader:FeedLoader {
    
    private let url:URL
    private let client:HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    /*
    //<Error> -> Error.connectivity / Error.invalidData (Domain Specific Error)
    public typealias Result = LoadFeedResult<DomainSpecificError.Error>
    public enum Error: DomainSpecificError.Error {
        case connectivity
        case invalidData
    }
    */
    
    public typealias Result = LoadFeedResult
    
    public init(url:URL, client:HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        print("\n\(type(of:self)): \(#function))")
        
        client.get(from: url) { [weak self] result in
            
            guard self != nil else { return }
        
            print("\(type(of:self)): \(#function)) result")
            
            switch result {
            case .success(let data, let response):
                completion(FeedItemsMapper.map(data, from: response))
            case .failure(_):
                completion(.failure(Error.connectivity))
            }
        }
    }
}
