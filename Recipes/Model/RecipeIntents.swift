//
//  RecipeIntents.swift
//  Recipes
//
//  Created by John on 29/05/2025.
//

import AppIntents
import SwiftData

// MARK: AppEntity - Recipe

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

// MARK: AppEnum - Recipe.Kind

enum RecipeKindAppEnum: String, AppEnum {
    case meal
    case sweet
    case other

    static var typeDisplayRepresentation = TypeDisplayRepresentation("Recipe Kind")

    static var caseDisplayRepresentations: [RecipeKindAppEnum : DisplayRepresentation] = [
        .meal: DisplayRepresentation(title: "Meal"),
        .sweet: DisplayRepresentation(title: "Sweets"),
        .other: DisplayRepresentation(title: "Other")
    ]

    init(_ kind: Recipe.Kind) {
        switch kind {
        case .meal: self = .meal
        case .sweet: self = .sweet
        case .other: self = .other
        }
    }

    var asRecipeKind: Recipe.Kind {
        switch self {
        case .meal: return .meal
        case .sweet: return .sweet
        case .other: return .other
        }
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

// MARK: AppIntent - Recipe Plan(/Unplan) Intent

struct RecipePlanIntent: AppIntent {
    static let title: LocalizedStringResource = "Plan Recipe"

    static let description = IntentDescription("Plan a recipe for cooking.")

    @Parameter(title: "Recipe", description: "The recipe to plan")
    var recipe: RecipeEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Plan \(\.$recipe)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let modelContext = DatabaseLoader.intentsModelContext
        let recipeModel = try Recipe.find(entity: recipe, modelContext: modelContext)
        recipeModel.doPlanAction(modelContext: modelContext)
        return .result()
    }
}

extension RecipePlanIntent {
    init(recipe: RecipeEntity) {
        self.recipe = recipe
    }
}

// MARK: AppIntent - Recipe Create From URL Intent

/// This is part of the 'share sheet' extension - rather than an actual share extension, which is all UIKit and
/// rather incomprehensible, we use ShortCuts as the glue to trigger this thing.
struct RecipeFromURLIntent: AppIntent {
    static let title: LocalizedStringResource = "Create Recipe"

    static let description = IntentDescription("Create a recipe from a web page.")

    @Parameter(title: "URL", description: "The URL of the new recipe's web page.")
    var url: String

    @Parameter(title: "Name", description: "The name of the new recipe.")
    var name: String

    @Parameter(title: "Kind", description: "The kind of the new recipe.")
    var kind: RecipeKindAppEnum

    @Parameter(title: "Amount", description: "The number of servings or amount of food the recipe makes.")
    var amount: String

    static var parameterSummary: some ParameterSummary {
        Summary("Add new \(\.$kind)-kind recipe called \(\.$name) from \(\.$url) that makes \(\.$amount).")
    }

    @MainActor
    func perform() async throws -> some ReturnsValue<RecipeEntity> {
        let modelContext = DatabaseLoader.intentsModelContext

        let books = try Book.all(modelContext: modelContext)
        var bestBook: Book? = nil
        for book in books {
            bestBook = book
            if book.name.localizedCaseInsensitiveContains("internet") {
                break
            }
        }

        guard let bestBook else {
            throw AppIntentError.Unrecoverable.entityNotFound
        }

        let servingsCount: UInt?
        let quantity: String?
        if amount.wholeMatch(of: /\d+/) != nil {
            servingsCount = UInt(amount)
            quantity = nil
        } else {
            servingsCount = nil
            quantity = amount
        }

        let recipe = Recipe(name: name, book: bestBook, pageNumber: nil, url: url,
                            kind: kind.asRecipeKind,
                            servingsCount: servingsCount, quantity: quantity,
                            isImported: false, notes: "SHARED")
        modelContext.insert(recipe)
        try? modelContext.save()

        return .result(value: RecipeEntity(recipe))
    }
}

// MARK: Shortcuts - for science & sharing

final class AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RecipeCookIntent(),
            phrases: [
                "Cook in \(.applicationName)"
            ],
            shortTitle: "Cook a recipe",
            systemImageName: "fork.knife"
        )
        AppShortcut(
            intent: RecipePlanIntent(),
            phrases: [
                "Plan in \(.applicationName)"
            ],
            shortTitle: "Plan a recipe",
            systemImageName: "calendar.badge.minus"
        )
        AppShortcut(intent: RecipeFromURLIntent(),
                    phrases: [
                        "Create recipe in \(.applicationName)"
                    ],
                    shortTitle: "Create a recipe from a web page",
                    systemImageName: "fork.knife.circle"
        )
    }
}
