//
//  SpotlightIndex.swift
//  Recipes
//
//  Created by John on 25/06/2026.
//

import CoreSpotlight
import AppIntents

///
/// Wrap up Spotlight interactions.
///
/// The docs say that `CSSearchableIndex` is not thread-safe.  Example code doesn't really
/// do this unless explicitly via MainActor, but do that here.
///
final class SpotlightIndex : NSObject, CSSearchableIndexDelegate {
    let index: CSSearchableIndex

    private override init() {
        index = CSSearchableIndex(name: "com.tml.recipes.index")
        super.init()

        if #unavailable(anyAppleOS 27) {
            index.indexDelegate = self
        }
    }

    static let shared = SpotlightIndex()

    private static func index<I: IndexedEntity>(entity: I) {
        Task { @MainActor in
            do {
                try await shared.index.indexAppEntities([entity])
            } catch {
                Log.log("CS::indexAppEntities: \(error) for entity \(entity.id)")
            }
        }
    }

    private static func delete<I: IndexedEntity>(entityType: I.Type, id: I.ID) {
        Task { @MainActor in
            do {
                try await shared.index.deleteAppEntities(
                    identifiedBy: [id], ofType: entityType)
            } catch {
                Log.log("CS::deleteAppEntities: \(error) for entity ID \(id)")
            }
        }
    }

    static func update(_ recipe: Recipe) {
        index(entity: RecipeEntity(recipe))
    }

    static func delete(_ recipe: Recipe) {
        delete(entityType: RecipeEntity.self, id: RecipeEntity(recipe).id)
    }

    static func update(_ book: Book) {
        index(entity: BookEntity(book))
    }

    static func delete(_ book: Book) {
        delete(entityType: BookEntity.self, id: BookEntity(book).id)
    }

    /// indexAll - used once on upgrade from software that does not support Spotlight indexing.
    @MainActor
    static func indexAll() async {
        let modelContext = DatabaseLoader.modelContainer.mainContext
        do {
            let recipes = try Recipe.all(modelContext: modelContext).map(RecipeEntity.init)
            try await shared.index.indexAppEntities(recipes)

            let books = try Book.all(modelContext: modelContext).map(BookEntity.init)
            try await shared.index.indexAppEntities(books)
        } catch {
            Log.log("CS::indexAll: \(error)")
        }
    }

    // For xOS27+, reindex is managed via the intents path
    // For earlier, we have to reindex via the delegate but everything else goes through the intents.
    @MainActor
    static func reindex(_ recipes: [RecipeEntity]) async throws {
        try await shared.index.indexAppEntities(recipes)
    }

    // This is all disposable at iOS27 ... not trying to be clever at all

    func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexAllSearchableItemsWithAcknowledgementHandler acknowledgementHandler: @escaping () -> Void) {
        Task { @MainActor in
            do {
                let modelContext = DatabaseLoader.modelContainer.mainContext
                let recipes = try Recipe.all(modelContext: modelContext).map(RecipeEntity.init)
                try await index.indexAppEntities(recipes)
            } catch {
                Log.log("CS::reindexAllSearchableItems: \(error)")
            }
            acknowledgementHandler()
        }
    }

    func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexSearchableItemsWithIdentifiers identifiers: [String], acknowledgementHandler: @escaping () -> Void) {
        Task { @MainActor in
            do {
                let modelContext = DatabaseLoader.modelContainer.mainContext
                let recipes = try Recipe.find(names: identifiers, modelContext: modelContext).map(RecipeEntity.init)
                try await index.indexAppEntities(recipes)
            } catch {
                Log.log("CS::reindexAllSearchableItems: \(error)")
            }
            acknowledgementHandler()
        }
    }
}
