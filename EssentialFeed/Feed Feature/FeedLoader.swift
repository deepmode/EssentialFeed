//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Eric Ho on 8/27/23.
//

import Foundation

public enum LoadFeedResult<Error:Swift.Error> {
    case success([FeedItem])
    case failure(Error)
}


protocol FeedLoader {
    associatedtype Error: Swift.Error
    
    func load(completion: @escaping (LoadFeedResult<Error>) -> Void)
}


