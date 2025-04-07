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
    @Namespace private var namespace
    //    @State private var cachedImages: [String: Image] = [:]
    //    let recipes = Recipe.sampleRecipes
    var body: some View {
        NavigationStack {
            ScrollView{
                if recipeVM.recipes.isEmpty {
                    ContentUnavailableView("No Recipes Available",
                                           systemImage: "",description: Text( "Please try again later"))
                    .padding()
                    .navigationTitle("Recipes")
                } else {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(recipeVM.filteredRecipes()) { recipe in
                            if #available(iOS 18.0, *) {
                                NavigationLink {
                                    RecipeDetailView(recipe: recipe)
                                        .navigationTransition(.zoom(sourceID: "zoomTransition\(recipe.id)", in: namespace))
                                } label: {
                                    RecipeRowView(recipe: recipe)
                                        .matchedTransitionSource(id: "zoomTransition\(recipe.id)", in: namespace)
                                }
                                .foregroundStyle(.primary)
                            } else {
                                NavigationLink {
                                    RecipeDetailView(recipe: recipe)
                                } label: {
                                    RecipeRowView(recipe: recipe)
                                }
                                .foregroundStyle(.primary)
                            }
                        }
                    }
                    .padding()
                    .environment(recipeVM)
                    .navigationTitle("Recipes")
                    .alert(isPresented: $showAlert, error: error, actions: { error in
                        Button("OK", role: .cancel) { }
                    }, message: { error in
                        Text(error.localizedDescription)
                    })
                    .searchable(text: $recipeVM.searchText, prompt: "Search recipes...")
                    .searchScopes($recipeVM.searchScope, scopes: {
                        ForEach(searchScope.allCases, id: \.self) { scope in
                            Text(scope.rawValue).tag(scope)
                        }
                    })
                }
            }
            .refreshable {
                await fetchRecipes()
            }
            .task {
                await fetchRecipes()
            }
        }
    }
    private func fetchRecipes() async {
        do {
            try await recipeVM.fetchAllRecipes()
        } catch {
            showAlert = true
            self.error = error as? NetworkError ?? NetworkError.invalidResponse
        }
    }
}


#Preview {
    RecipeListView()
}
