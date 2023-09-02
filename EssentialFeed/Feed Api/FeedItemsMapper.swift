//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Eric Ho on 9/2/23.
//

import Foundation

internal final class FeedItemsMapper {
    
    //DTO
    private struct Root: Decodable {
        let items:[Item]
        
        var feed:[FeedItem] {
            return items.map { $0.item }
        }
    }

    //DTO
    private struct Item: Decodable {
        let id:UUID
        let description:String?
        let location:String?
        let image:URL
        
        var item: FeedItem {
            return FeedItem(id: id, description: description, location: location, imageURL: image)
        }
    }
    
    private static var OK_200: Int { return 200}
    
    internal static func map(_ data: Data, from response:HTTPURLResponse) -> RemoteFeedLoader.Result {
        
        guard response.statusCode == OK_200,
            let root = try? JSONDecoder().decode(Root.self, from: data) else  {
            return  .failure(.invalidData)
        }
        
        //DTO (Data Transfer Object) -> App Models e.g. Root -> [FeedItem]
        return .success(root.feed)
        
    }
}
