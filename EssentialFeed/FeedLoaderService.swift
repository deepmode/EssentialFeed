//
//  FeedLoaderService.swift
//  EssentialFeed
//
//  Created by Eric Ho on 8/27/23.
//

import Foundation

class FeedLoaderService:FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void) {
        URLSession.shared.dataTask(with: URLRequest(url: URL(string: "https://hypebeast.com")!)) { data, respose, error in
            completion(.success([FeedItem(id: UUID(), description: "description", location: "location", image: "https://hypebeast.com")]))
        }.resume()
    }
    
}
