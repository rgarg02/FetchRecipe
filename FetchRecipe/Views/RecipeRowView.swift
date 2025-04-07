//
//  RecipeRowView.swift
//  FetchRecipe
//
//  Created by Rishi Garg on 4/6/25.
//  Modified to reset error state on alert dismissal.
//

import SwiftUI

struct RecipeRowView: View {
    @Environment(RecipeViewModel.self) private var recipeVM
    let recipe: Recipe
    @State private var imageData: Data?
    @State private var currentError: LocalizedError?
    @State private var showAlert = false

    var body: some View {
        HStack {
            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if currentError == nil {
                ProgressView()
                 .frame(width: 50, height: 50)
            } else {
                 Image(systemName: "exclamationmark.triangle")
                     .resizable()
                     .scaledToFit()
                     .frame(width: 40, height: 40)
                     .foregroundColor(.red)
                      .frame(width: 50, height: 50)
            }

            VStack(alignment: .leading) {
                Text(recipe.name)
                    .font(.headline)
                Text(recipe.cuisine)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .alert("Error Loading Image", isPresented: $showAlert, presenting: currentError) { error in
            Button("OK") {
                currentError = nil
            }
        } message: { error in
            Text(error.localizedDescription)
        }
        .task {
             currentError = nil
             imageData = nil
            if let photoUrlSmall = recipe.photoUrlSmall {
                do {
                    imageData = try await recipeVM.fetchImageData(urlString: photoUrlSmall)
                } catch let localizedError as LocalizedError {
                     currentError = localizedError
                     showAlert = true
                } catch {
                     currentError = NetworkError.invalidResponse
                     showAlert = true
                 }
            }
        }
    }
}

#Preview {
    let recipe = Recipe.sampleRecipes[0]
     return List {
         RecipeRowView(recipe: recipe)
             .environment(RecipeViewModel())
             .padding()
     }
}
