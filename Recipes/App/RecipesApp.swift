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
    }
}

struct AppTabView: View {
    @Environment(\.modelContext) var modelContext

    @State var selectedTab = ""
    @State var invokedRecipe: Recipe?

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Recipes", systemImage: "fork.knife.circle", value: "Recipes") {
                RecipesView(invokedRecipe: $invokedRecipe)
            }
            Tab("History", systemImage: "clock.fill", value: "History") {
                HistoryView()
            }
            Tab("Books", systemImage: "books.vertical.circle", value: "Books") {
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
            selectedTab = "Recipes"
            invokedRecipe = recipe
        }
    }
}

#Preview(traits: .previewObjects) {
    AppTabView()
}
