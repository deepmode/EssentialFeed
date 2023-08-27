//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Eric Ho on 8/27/23.
//

import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case error(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}


