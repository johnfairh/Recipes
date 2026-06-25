//
//  RecipeIntents.swift
//  Recipes
//
//  Created by John on 29/05/2025.
//

import AppIntents
import SwiftData
import CoreSpotlight

// MARK: AppEntity - Recipe

struct RecipeEntity: IndexedEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation("Recipe")

    static var defaultQuery = RecipeEntityQuery()

    /// Recipe object unique ID: we use the name.
    ///
    /// This is a kludge because the name is not unique.  SwiftData has an `id` but it is a weird
    /// compound opaque thing that can only be JSONified to get something.
    ///
    /// The work needed is to add a new UUID field to each object (lesson learnt, put this in from
    /// the start next time) and rejigger everything to use it.
    let id: String
    let kind: Recipe.Kind

    @Property(title: "Recipe Name")
    var name: String

    @Property(title: "Recipe location")
    var location: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)",
                              subtitle: "\(location)",
                              image: .init(systemName: kind.systemImageName))
    }

    static func identifier(_ id: ID) -> EntityIdentifier {
        EntityIdentifier(for: Self.self, identifier: id)
    }

    init(_ recipe: Recipe) {
        self.id = recipe.name
        self.kind = recipe.kind
        self.name = recipe.name
        self.location = recipe.location
    }
}

extension Recipe {
    var entityIdentifier: EntityIdentifier {
        RecipeEntity.identifier(name)
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

struct RecipeEntityQuery: EnumerableEntityQuery, IndexedEntityQuery {
    @MainActor
    func entities(for identifiers: [RecipeEntity.ID]) async throws -> [RecipeEntity] {
        try Recipe.find(names: identifiers, modelContext: DatabaseLoader.intentsModelContext)
            .map(RecipeEntity.init)
    }

    @MainActor
    func suggestedEntities() async throws -> [RecipeEntity] {
        try await allEntities()
    }

    @MainActor
    func allEntities() async throws -> [RecipeEntity] {
        try Recipe.all(modelContext: DatabaseLoader.intentsModelContext)
            .map(RecipeEntity.init)
    }

    @available(iOS 27.0, *)
    @MainActor
    func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
        let recipes = try await allEntities()
        try await SpotlightIndex.reindex(recipes)
    }

    @available(iOS 27.0, *)
    @MainActor
    func reindexEntities(for identifiers: [String], indexDescription: CSSearchableIndexDescription) async throws {
        let recipes = try await entities(for: identifiers)
        try await SpotlightIndex.reindex(recipes)
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
        recipeModel.doCookAction(modelContext: modelContext, fromIntent: true)
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
        recipeModel.doPlanAction(modelContext: modelContext, fromIntent: true)
        return .result()
    }
}

extension RecipePlanIntent {
    init(recipe: RecipeEntity) {
        self.recipe = recipe
    }
}

// MARK: AppIntent - Recipe Pin(/Unpin) Intent

struct RecipePinIntent: AppIntent {
    static let title: LocalizedStringResource = "Pin Recipe"

    static let description = IntentDescription("Pin a recipe to cook later.")

    @Parameter(title: "Recipe", description: "The recipe to pin")
    var recipe: RecipeEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Pin \(\.$recipe)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let modelContext = DatabaseLoader.intentsModelContext
        let recipeModel = try Recipe.find(entity: recipe, modelContext: modelContext)
        recipeModel.doPinAction(modelContext: modelContext, fromIntent: true)
        return .result()
    }
}

extension RecipePinIntent {
    init(recipe: RecipeEntity) {
        self.recipe = recipe
    }
}

// MARK: AppIntent - Recipe Delete Intent

struct RecipeDeleteIntent: AppIntent {
    static let title: LocalizedStringResource = "Delete Recipe"

    static let description = IntentDescription("Delete a recipe.")

    @Parameter(title: "Recipe", description: "The recipe to delete")
    var recipe: RecipeEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Delete \(\.$recipe)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let modelContext = DatabaseLoader.intentsModelContext
        let recipeModel = try Recipe.find(entity: recipe, modelContext: modelContext)
        recipeModel.doDeleteAction(modelContext: modelContext, fromIntent: true)
        return .result()
    }
}

extension RecipeDeleteIntent {
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
            if book.shortName.localizedCaseInsensitiveContains("internet") {
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
                            isImported: false, notes: "")
        modelContext.insert(recipe)
        try? modelContext.save()

        return .result(value: RecipeEntity(recipe))
    }
}

// MARK: AppIntent - Open Recipe In App Intent

//@AppIntent(schema: .system.open)
struct OpenRecipeIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Recipe"

    @Parameter(title: "Recipe")
    var target: RecipeEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        let modelContext = DatabaseLoader.intentsModelContext
        let recipe = try Recipe.find(entity: target, modelContext: modelContext)
        UIState.shared.show(recipe: recipe)
        return .result()
    }
}

// This doesn't even compile...
//
// Wait for iOS27 to be tbe minimum
//
//@AppIntent(schema: .system.searchInApp)
//struct SystemSearchInAppIntent: ShowInAppSearchResultsIntent {
//    @available(anyAppleOS 27, *)
//    static var searchScopes: [StringSearchScope] = [.general]
//
//    @available(anyAppleOS 27, *)
//    @Parameter(title: "Search")
//    var criteria: StringSearchCriteria
//
//    @available(anyAppleOS 27, *)
//    @MainActor
//    func perform() async throws -> some IntentResult {
//        .result()
//    }
//}
