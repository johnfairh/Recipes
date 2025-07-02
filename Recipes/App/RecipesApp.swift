//
//  RecipesApp.swift
//  Recipes
//
//  Created by John on 11/02/2025.
//

import SwiftUI
import SwiftData

@main
struct RecipesApp: App {
    var body: some Scene {
        WindowGroup {
            AppTabView()
        }
        .modelContainer(DatabaseLoader.modelContainer)
        .environment(Log.shared)
        .environment(UIState())
    }
}

struct AppTabView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(UIState.self) var uiState: UIState

    var body: some View {
        @Bindable var uiState = uiState
        TabView(selection: $uiState.selectedTab) {
            Tab("Recipes", systemImage: "fork.knife.circle", value: UIState.TabValue.recipes) {
                RecipesView()
            }
            Tab("History", systemImage: "clock.fill", value: UIState.TabValue.history) {
                HistoryView()
            }
            Tab("Books", systemImage: "books.vertical.circle", value: UIState.TabValue.books) {
                BooksView()
            }
        }
        .onOpenURL { url in
            Log.log("URL: \(url)")
            let path = url.path(percentEncoded: false)
            Log.log("URL-path: \(path)")
            guard path.count > 1,
                  let recipe = try? Recipe.find(name: String(path.dropFirst()), modelContext: modelContext) else {
                Log.log("URl-!found-recipe")
                return
            }

            Log.log("URL-found-recipe: \(recipe.name)")
            uiState.selectedTab = .recipes
            uiState.selectedRecipe = recipe
        }
    }
}

#Preview(traits: .previewObjects) {
    AppTabView()
}
