//
//  Schemas.swift
//  Recipes
//
//  Created by John on 25/02/2025.
//
import SwiftData

// MARK: Schemas

enum Version1Schema: VersionedSchema {
    static var models: [any PersistentModel.Type] = [
        Recipe.self,
        Book.self
    ]

    static var versionIdentifier = Schema.Version(0, 0, 1)
}

enum Version2Schema: VersionedSchema {
    static var models: [any PersistentModel.Type] = [
        Recipe.self,
        Book.self,
        Cooking.self
    ]

    static var versionIdentifier = Schema.Version(0, 0, 2)

    static func didMigrate(modelContext: ModelContext) throws {
        let recipes = try modelContext.fetch(FetchDescriptor<Recipe>())

        Log.log("Schema Version Migration 1->2")

        for recipe in recipes {
            guard let lastCooked = recipe.actualLastCookedTime else {
                continue
            }

            let cooking = Cooking(recipe: recipe, notes: nil)
            modelContext.insert(cooking)
        }

        try modelContext.save()
    }
}

// MARK: Common

typealias CurrentSchema = Version2Schema

typealias Recipe = CurrentSchema.Recipe
typealias Book = CurrentSchema.Book
typealias Cooking = CurrentSchema.Cooking

// MARK: Migration Plan

enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [
        Version1Schema.self,
        Version2Schema.self
    ]

    static var stages: [MigrationStage] = [
        /// Populate `Cooking` on introduction
        .custom(fromVersion: Version1Schema.self,
                toVersion: Version2Schema.self,
                willMigrate: nil,
                didMigrate: Version2Schema.didMigrate)
    ]
}
