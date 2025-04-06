//
//  SampleRecipes.swift
//  FetchRecipe
//
//  Created by Rishi Garg on 4/6/25.
//

import Foundation

// MARK: - Recipe Model
/// Recipe Model based on the JSON structure from the API
/// Conforms to Identifiable to use in SwiftUI ForEach blocks
/// Conforms to Codable for easy JSON encoding and decoding
struct Recipe: Identifiable, Codable {
    let cuisine: String
    let name: String
    let photoUrlLarge: String?
    let photoUrlSmall: String?
    let id: String
    let sourceUrl: String?
    let youtubeUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case cuisine
        case name
        case photoUrlLarge = "photo_url_large"
        case photoUrlSmall = "photo_url_small"
        case id = "uuid"
        case sourceUrl = "source_url"
        case youtubeUrl = "youtube_url"
    }
}

struct RecipeList: Codable {
    var recipes: [Recipe]
}

