//
//  RecipeListView.swift
//  FetchRecipe
//
//  Created by Rishi Garg on 4/6/25.
//
import SwiftUI
struct RecipeListView: View {
    @State private var recipeVM = RecipeViewModel()
    @State private var showAlert = false
    @State private var error = NetworkError.invalidResponse
//    @State private var cachedImages: [String: Image] = [:]
    //    let recipes = Recipe.sampleRecipes
    var body: some View {
        NavigationView {
            List(recipeVM.recipes) { recipe in
                RecipeRowView(recipe: recipe)
            }
            .environment(recipeVM)
            .navigationTitle("Recipes")
            .alert(isPresented: $showAlert, error: error, actions: { error in
                Button("OK", role: .cancel) { }
            }, message: { error in
                Text(error.localizedDescription)
            })
            .task {
                do {
                    try await recipeVM.fetchAllRecipes()
                } catch {
                    showAlert = true
                    self.error = error as? NetworkError ?? NetworkError.invalidResponse
                }
            }
        }
    }
}

struct RecipeRowView: View {
    @Environment(RecipeViewModel.self) private var recipeVM
    let recipe: Recipe
    @State private var imageData: Data?
    var body: some View {
        HStack {
            if let imageData, let uiImage = UIImage(data: imageData){
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ProgressView()
            }
            VStack(alignment: .leading) {
                Text(recipe.name).font(.headline)
                Text(recipe.cuisine).font(.subheadline).foregroundColor(.secondary)
            }
        }
        .task {
            if let photoUrlSmall = recipe.photoUrlSmall {
                do {
                    imageData = try await recipeVM.fetchImageData(urlString: photoUrlSmall)
                } catch {
                    print("Error fetching image: \(error)")
                }
            }
        }
    }
}

// You can preview this view in Xcode
struct RecipeListView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeListView()
    }
}
