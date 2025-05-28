//
//  RecipeView.swift
//  Recipes
//
//  Created by John on 27/05/2025.
//

import SwiftUI

struct RecipeView: View {
    @Environment(\.modelContext) var modelContext

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
                Text(recipe.name).font(.title3)
                Spacer()
                Button("Edit") {
                    isShowingEdit = true
                }
            }
            if let servings = recipe.servings {
                Text(servings).font(.body)
            }
            Text(recipe.location)

            // tbd add some vspace here :(
            if let lastCookedText = recipe.lastCookedText {
                Text(lastCookedText) // tbd link to history
                // tbd exact date
            }
            // tbd first made X, made Y times total

            // tbd vspace

            if let url = recipe.url {
                Text(url)
                // tbd linkable
            }

            // tbd presentation
            Text(recipe.notes)
        }
        .padding()
        .sheet(isPresented: $isShowingEdit) {
            CreateEditRecipeView(parentModelContext: modelContext, recipe: recipe)
        }
        Spacer()
    }
}
