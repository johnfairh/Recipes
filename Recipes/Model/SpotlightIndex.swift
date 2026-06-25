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
struct SpotlightIndex {
    let index: CSSearchableIndex

    private init() {
        index = CSSearchableIndex(name: "com.tml.recipes.index")
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
}
