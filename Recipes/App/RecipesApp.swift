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
    }
}

struct AppTabView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Recipes", systemImage: "fork.knife.circle")
                }

            ContentView()
                .tabItem {
                    Label("Recipe Books", systemImage: "books.vertical.circle")
                }
        }
    }
}
