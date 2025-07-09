//
//  RecipesView.swift
//  Recipes
//
//  Created by John on 12/02/2025.
//

import UIKit
import SwiftUI
import SwiftData

struct RecipesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(UIState.self) var uiState: UIState

    var body: some View {
        @Bindable var uiState = uiState.recipesTab
        NavigationSplitView {
            List {
                RecipesListView(searchText: uiState.searchText)
            }
            .navigationTitle("Recipes")
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
                if uiState.filterList != nil {
                    ToolbarItem {
                        Button {
                            uiState.filterList = nil
                        } label: {
                            Image("custom.line.3.horizontal.decrease.2.slash")
                        }
                    }
                }
                ToolbarItem {
                    Button("Filter", systemImage: "line.3.horizontal.decrease") {
                        uiState.sheet = .filter
                    }
                }
                ToolbarItem {
                    Button("Add Recipe", systemImage: "plus") {
                        uiState.sheet = .create
                    }
                }
            }
            .searchable(text: $uiState.searchText, placement: .navigationBarDrawer, prompt: "Recipe name or notes")
        } detail: {
            Text("Select an item")
        }
        .sheet(isPresented: .asBool($uiState.sheet)) {
            switch uiState.sheet {
            case .none: EmptyView()
            case .create:
                CreateEditRecipeView(parentModelContext: modelContext)
            case .filter:
                RecipeFilterView(filterList: $uiState.filterList)
                    .presentationDetents([.fraction(0.33), .medium, .large])
                    .presentationDragIndicator(.hidden)
            }
        }
        .sheet(item: $uiState.selected) { itm in
            RecipeView(recipe: itm)
                .presentationDetents([.fraction(0.33), .medium, .large])
                .presentationDragIndicator(.hidden)
        }
    }
}

extension Recipe {
    func backgroundColor(isSelected: Bool) -> Color {
        let ui: UIColor = isSelected ? .tertiarySystemGroupedBackground : .secondarySystemGroupedBackground
        return Color(ui)
    }
}

/// The list view - lives inside List
/// Seach done in the DB, filter done in code (because #Predicate not good enough)
struct RecipesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(UIState.self) var uiState: UIState

    private let searchText: String

    @SectionedQuery
    private var recipes: SectionedResults<Recipe.Lifecycle, Recipe>

    init(searchText: String) {
        self.searchText = searchText
        let predicate = #Predicate<Recipe> { recipe in
            searchText.isEmpty ||
            recipe.name.localizedStandardContains(searchText) ||
            recipe.notes.localizedStandardContains(searchText)
        }
        _recipes = SectionedQuery(\.lifecycle, filter: predicate, sort: [
            .init(\.lifecycleRaw, order: .forward),
            .init(\.name, order: .forward)
        ])
    }

    var filteredRecipes: SectionedResults<Recipe.Lifecycle, Recipe> {
        uiState.recipesTab.filterList.map { fl in recipes.filter { fl.pass(recipe: $0) } } ?? recipes
    }

    var body: some View {
        @Bindable var uiState = uiState.recipesTab
        if !searchText.isEmpty && filteredRecipes.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else if uiState.filterList != nil && filteredRecipes.isEmpty {
            ContentUnavailableView(
                "No Filtered Results",
                systemImage: "line.3.horizontal.decrease",
                description: Text("Clear or edit the filters"))
        } else {
            ForEach(filteredRecipes) { section in
                Section(section.id.name) {
                    ForEach(section) { recipe in
                        HStack {
                            Image(systemName: recipe.symbolName)
                                .imageScale(.large)
                                .foregroundStyle(Color.accentColor)
                                .frame(minWidth: 32, maxWidth: 32)
                            VStack(alignment: .leading) {
                                Text(recipe.name).font(.title3)
                                if let lastCookedText = recipe.lastCookedText {
                                    Text(lastCookedText).font(.body)
                                }
                            }
                            .padding(.leading, 8)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if uiState.selected == recipe {
                                uiState.selected = nil
                            } else {
                                uiState.selected = recipe
                            }
                        }
                        .listRowBackground(recipe.backgroundColor(isSelected: uiState.selected == recipe))
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            // Cooking
                            Button(recipe.cookActionName, systemImage: recipe.cookActionIconName) {
                                recipe.doCookAction(modelContext: modelContext)
                            }
                            .tint(.green)

                            // Planning
                            Button(recipe.planActionName, systemImage: recipe.planActionIconName) {
                                recipe.doPlanAction(modelContext: modelContext)
                            }
                            .tint(.blue)

                            // Pinning
                            Button(recipe.pinActionName, systemImage: recipe.pinActionIconName) {
                                recipe.doPinAction(modelContext: modelContext)
                            }
                            .tint(.yellow)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                recipe.doDeleteAction(modelContext: modelContext)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview(traits: .previewObjects) {
    RecipesView()
}
