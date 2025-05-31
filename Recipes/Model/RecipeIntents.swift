//
//  RecipeIntents.swift
//  Recipes
//
//  Created by John on 29/05/2025.
//

import AppIntents
import SwiftData

// MARK: AppIntent - Recipe

struct RecipeEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation("Recipe")

    static var defaultQuery = RecipeEntityQuery()

    /// Recipe object unique ID: we use the name
    let id: String

    @Property(title: "Recipe Name")
    var name: String

    @Property(title: "Recipe location")
    var location: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name) (\(location))")
    }

    init(_ recipe: Recipe) {
        self.id = recipe.name
        self.name = recipe.name
        self.location = recipe.location
    }
}

// MARK: AppIntent - Recipe Queries

struct RecipeEntityQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [RecipeEntity.ID]) async throws -> [RecipeEntity] {
        try Recipe.find(names: identifiers, modelContext: DatabaseLoader.intentsModelContext)
            .map(RecipeEntity.init)
    }

    @MainActor
    func suggestedEntities() async throws -> [RecipeEntity] {
        try Recipe.all(modelContext: DatabaseLoader.intentsModelContext)
            .map(RecipeEntity.init)
    }
}

// MARK: AppIntent - Recipe Cook Intent

struct RecipeCookIntent: AppIntent {
    static let title: LocalizedStringResource = "Cook Recipe"

    static let description = IntentDescription("Marks a recipe as cooked.")

    @Parameter(title: "Recipe", description: "The recipe to cook")
    var recipe: RecipeEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Cook \(\.$recipe)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let modelContext = DatabaseLoader.intentsModelContext
        let recipeModel = try Recipe.find(entity: recipe, modelContext: modelContext)
        recipeModel.doCookAction(modelContext: modelContext)
        return .result()
    }
}

extension RecipeCookIntent {
    init(recipe: RecipeEntity) {
        self.recipe = recipe
    }
}

// MARK: Shortcuts - for science...

class AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RecipeCookIntent(),
            phrases: [
                "Cook in \(.applicationName)"
            ],
            shortTitle: "Cook a recipe",
            systemImageName: "fork.knife"
        )
    }
}
