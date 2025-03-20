//
//  RecipesView.swift
//  Recipes
//
//  Created by John on 12/02/2025.
//


import SwiftUI
import SwiftData

extension Recipe {
    func backgroundColor(isSelected: Bool) -> Color {
        let ui: UIColor = isSelected ? .tertiarySystemGroupedBackground : .secondarySystemGroupedBackground
        return Color(ui)
    }
}

struct RecipesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.name) private var recipes: [Recipe]

    @State private var selected: Recipe? = nil

    @State private var isShowingCreate: Bool = false

    @State private var searchText: String = ""

    var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return recipes
        }
        return recipes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationSplitView {
            List {
                if !searchText.isEmpty && filteredRecipes.isEmpty {
                    ContentUnavailableView.search
                } else {
                    ForEach(filteredRecipes) { recipe in
                        HStack {
                            Image(systemName: recipe.symbolName)
                                .imageScale(.large)
                                .foregroundStyle(Color.accentColor)
                                .frame(minWidth: 32, maxWidth: 32)
                            VStack(alignment: .leading) {
                                Text(recipe.name).font(.title3)
                                if let servings = recipe.servings {
                                    Text(servings).font(.body)
                                }
                                if selected == recipe {
                                    Text(recipe.location)
                                    // url
                                    // notes
                                    // creation date
                                    if let lastCookedText = recipe.lastCookedText {
                                        Text(lastCookedText)
                                    }
                                }
                            }
                            .padding(.leading, 8)
                            Spacer()
                        }
                        .contentShape(Rectangle()) // this makes the hittest cover the entire cell...
                        .onTapGesture {
                            if selected == recipe {
                                selected = nil
                            } else {
                                selected = recipe
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(recipe.backgroundColor(isSelected: selected == recipe))
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button("Cooked", systemImage: "fork.knife") {
                                Log.log("Update cooked for recipe '\(recipe.name)'")
                                recipe.updateLastCookedTime()
                                modelContext.trySave()
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                Log.log("Delete recipe '\(recipe.name)'")
                                modelContext.delete(recipe)
                                modelContext.trySave()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Recipes")
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
                ToolbarItem {
                    Button("Undo", systemImage: "arrow.uturn.backward") {
                        withAnimation {
                            modelContext.undo()
                        }
                    }
                }
                ToolbarItem {
                    Button("Add Recipe", systemImage: "plus") {
                        isShowingCreate = true
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "Recipe name")
        } detail: {
            Text("Select an item")
        }
        .sheet(isPresented: $isShowingCreate) {
            CreateRecipeView()
        }
    }
}

#Preview(traits: .previewObjects) {
    RecipesView()
}
