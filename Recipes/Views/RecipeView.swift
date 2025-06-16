//
//  RecipeView.swift
//  Recipes
//
//  Created by John on 27/05/2025.
//

import SwiftUI

struct RecipeView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) private var dismiss

    private let recipe: Recipe

    init(recipe: Recipe) {
        self.recipe = recipe
    }

    @State private var isShowingEdit: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: recipe.symbolName)
                    .imageScale(.large)
                    .foregroundStyle(Color.accentColor)
                    .frame(minWidth: 32, maxWidth: 32)
                Text(recipe.name).font(.title)
            }.padding(.bottom, 2)
            VStack(alignment: .leading) {
                if let firstMade = recipe.firstCookedTextLong {
                    Text(firstMade)
                }
                Text(recipe.lastCookedTextLong)
            }.padding(.bottom, 2)
            VStack(alignment: .leading) {
                Text("From \(Image(systemName: recipe.book.symbolName))\(recipe.location).")
                Text(recipe.servings).font(.body)
                if let urlText = recipe.url, let url = URL(string: urlText) {
                    let host = url.host(percentEncoded: false).map { " (\($0))" } ?? "."
                    Link("On the web\(host)", destination: url)
                }
            }.padding(.bottom, 2)

            Text(recipe.notes)

            HStack {
                Spacer()
                HStack {
                    Button("", systemImage: "clock") {}
                    Button("", systemImage: recipe.cookActionIconName) {
                        recipe.doCookAction(modelContext: modelContext)
                    }
                    Button("", systemImage: recipe.planActionIconName) {
                        recipe.doPlanAction(modelContext: modelContext)
                    }
                    Button("", systemImage: recipe.pinActionIconName) {
                        recipe.doPinAction(modelContext: modelContext)
                    }
                    Button("", systemImage: "square.and.pencil") {
                        isShowingEdit = true
                    }
                    Button("", systemImage: "trash", role: .destructive) {
                        recipe.doDeleteAction(modelContext: modelContext)
                        dismiss()
                    }
                }
                .buttonBorderShape(.capsule)
                .padding()
                .background(.regularMaterial)
                .clipShape(.capsule)
                Spacer()
            }
        }
        .padding()
        .sheet(isPresented: $isShowingEdit) {
            CreateEditRecipeView(parentModelContext: modelContext, recipe: recipe)
        }
        Spacer()
    }
}

import SwiftData

private struct RecipePreviewView: View {
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    var body: some View {
        if let recipe = recipes.first {
            RecipeView(recipe: recipe)
        }
    }
}

#Preview(traits: .previewObjects) {
    RecipePreviewView()
}
