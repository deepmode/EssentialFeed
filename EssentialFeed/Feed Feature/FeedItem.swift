//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Eric Ho on 8/27/23.
//

import Foundation

public struct FeedItem: Equatable {
    let id:UUID
    let description:String?
    let location:String?
    let image:String
}
