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

extension UIState.TabValue {
    var systemImage: String {
        switch self {
        case .recipes: return "fork.knife.circle"
        case .history: return "clock.fill"
        case .books: return "books.vertical.circle"
        }
    }

    @ViewBuilder
    var view: some View {
        switch self {
        case .recipes: RecipesView()
        case .history: HistoryView()
        case .books: BooksView()
        }
    }
}

struct AppTabView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(UIState.self) var uiState: UIState

    var body: some View {
        @Bindable var uiState = uiState
        TabView(selection: $uiState.selectedTab) {
            ForEach(UIState.TabValue.allCases, id: \UIState.TabValue.rawValue) { value in
                Tab(value.rawValue, systemImage: value.systemImage, value: value) {
                    value.view
                }
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
            uiState.show(recipe: recipe)
        }
    }
}

#Preview(traits: .previewObjects) {
    AppTabView()
}
