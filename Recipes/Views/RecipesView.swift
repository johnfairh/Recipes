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

extension Bool: @retroactive Comparable {
    public static func <(lhs: Self, rhs: Self) -> Bool {
        !lhs && rhs
    }
}

struct RecipesView: View {
    @Environment(\.modelContext) private var modelContext

    @SectionedQuery(\Recipe.flagged, sort: [
        .init(\Recipe.flagged, order: .reverse),
        .init(\Recipe.name, order: .forward)
    ])
    private var recipes: SectionedResults<Bool, Recipe>

    @State private var selected: Recipe? = nil

    @State private var isShowingCreate: Bool = false

    @State private var searchText: String = ""

    var filteredRecipes: SectionedResults<Bool, Recipe> {
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
                    ForEach(filteredRecipes) { section in
                        Section(section.id ? "Flagged" : "Regular") {
                            ForEach(section) { recipe in
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
                                        let cooking = Cooking(recipe: recipe, notes: nil, timestamp: recipe.lastCookedTime)
                                        modelContext.insert(cooking)
                                        modelContext.trySave()
                                    }
                                    .tint(.green)
                                    Button(recipe.flagged ? "Unflag" : "Flag", systemImage: "flag") {
                                        Log.log("Updated flagged for recipe '\(recipe.name)'")
                                        recipe.flagged.toggle()
                                        modelContext.trySave()
                                    }
                                    .tint(.blue)
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

/*
 var body: some View {
     NavigationSplitView {
         if !searchText.isEmpty && filteredRecipes.isEmpty {
             ContentUnavailableView.search
         } else {
             List(filteredRecipes) { section in
                 Section(section.id) {
                     ForEach(section) { recipe in
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
                                 Text("FLAGGED = \(recipe.flagged)")
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

 */
