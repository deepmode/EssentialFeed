//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Eric Ho on 8/27/23.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedItem])
    case failure(Error)
}


public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
