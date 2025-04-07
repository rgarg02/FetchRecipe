//
//  RecipeDetailView.swift
//  FetchRecipe
//
//  Created by Rishi Garg on 4/6/25.
//

import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if let photoUrl = recipe.photoUrlLarge, let url = URL(string: photoUrl) {
                    // Based on phase
                    // Using AsyncImage to load the image asynchronously
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .cornerRadius(8)
                        case .failure:
                            Image(systemName: "exclamationmark.triangle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .cornerRadius(8)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                Text(recipe.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 8)
                
                Text(recipe.cuisine)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let sourceUrl = recipe.sourceUrl, let url = URL(string: sourceUrl) {
                    Link("Source", destination: url)
                        .padding(.top, 8)
                        .foregroundColor(.blue)
                }
                
                if let youtubeUrl = recipe.youtubeUrl, let url = URL(string: youtubeUrl) {
                    Link("Watch on YouTube", destination: url)
                        .padding(.top, 8)
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .navigationTitle("Recipe Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let recipe = Recipe.sampleRecipes[0]
    RecipeDetailView(recipe: recipe)
}
