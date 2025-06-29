//
//  RecipesView.swift
//  Recipes
//
//  Created by John on 12/02/2025.
//

import UIKit
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

    @Namespace private var namespace

    @SectionedQuery(\Recipe.lifecycle, sort: [
        .init(\.lifecycleRaw, order: .forward),
        .init(\.name, order: .forward)
    ])
    private var recipes: SectionedResults<Recipe.Lifecycle, Recipe>

    @State private var selected: Recipe? = nil

    @State private var isShowingCreate: Bool = false
    @State private var isShowingFilter: Bool = false

    @State private var searchText: String = ""

    @Binding private var invokedRecipe: Recipe?

    @State private var filterList: RecipeFilterList? = nil

    init(invokedRecipe: Binding<Recipe?>) {
        self._invokedRecipe = invokedRecipe
    }

    var filteredRecipes: SectionedResults<Recipe.Lifecycle, Recipe> {
        let filtered: SectionedResults<Recipe.Lifecycle, Recipe>

        if let filterList {
            filtered = recipes.filter { filterList.pass(recipe: $0) }
        } else {
            filtered = recipes
        }

        if searchText.isEmpty {
            return filtered
        }
        return filtered.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationSplitView {
            List {
                if !searchText.isEmpty && filteredRecipes.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else if filterList != nil && filteredRecipes.isEmpty {
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
                                    if selected == recipe {
                                        selected = nil
                                    } else {
                                        selected = recipe
                                    }
                                }
                                .listRowBackground(recipe.backgroundColor(isSelected: selected == recipe))
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
                                .matchedTransitionSource(id: "r-info", in: namespace)
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
                if filterList != nil {
                    ToolbarItem {
                        Button {
                            filterList = nil
                        } label: {
                            Image("custom.line.3.horizontal.decrease.badge.xmark")
                        }
                        .padding(.top, 9)
                    }
                }
                ToolbarItem {
                    Button("Filter", systemImage: "line.3.horizontal.decrease") {
                        isShowingFilter = true
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
            CreateEditRecipeView(parentModelContext: modelContext)
        }
        .sheet(isPresented: $isShowingFilter) {
            RecipeFilterView(filterList: $filterList)
                .presentationDetents([.fraction(0.33), .medium, .large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(item: $selected) { itm in
            RecipeView(recipe: itm)
                .presentationDetents([.fraction(0.33), .medium, .large])
                .presentationDragIndicator(.hidden)
                .navigationTransition(.zoom(sourceID: "r-info", in: namespace))
        }
        .onChange(of: invokedRecipe) {
            if selected == nil && invokedRecipe != nil {
                selected = invokedRecipe
            }
            invokedRecipe = nil
        }
    }
}

struct RecipesContainerView: View {
    @State var invocation: Recipe?

    var body: some View {
        RecipesView(invokedRecipe: $invocation)
    }
}

#Preview(traits: .previewObjects) {
    RecipesContainerView()
}
