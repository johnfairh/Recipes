//
//  Schemas.swift
//  Recipes
//
//  Created by John on 25/02/2025.
//
import SwiftData
import Foundation

// MARK: Schemas

enum Version1Schema: VersionedSchema {
    static var models: [any PersistentModel.Type] = [
        Version1Schema.Recipe.self,
        Version1Schema.Book.self
    ]

    static var versionIdentifier = Schema.Version(0, 0, 1)
}

enum Version2Schema: VersionedSchema {
    static var models: [any PersistentModel.Type] = [
        Version2Schema.Recipe.self,
        Version2Schema.Book.self,
        Version2Schema.Cooking.self
    ]

    static var versionIdentifier = Schema.Version(0, 0, 2)

    static func didMigrate(modelContext: ModelContext) throws {
        let recipes = try modelContext.fetch(FetchDescriptor<Version2Schema.Recipe>())

        Log.log("Schema Version Migration 1->2")

        for recipe in recipes {
            guard let lastCooked = recipe.actualLastCookedTime else {
                continue
            }

            let cooking = Version2Schema.Cooking(recipe: recipe, notes: nil, timestamp: lastCooked)
            modelContext.insert(cooking)
        }

        try modelContext.save()
    }
}

enum Version3Schema: VersionedSchema {
    static var models: [any PersistentModel.Type] = [
        Version3Schema.Recipe.self,
        Version3Schema.Book.self,
        Version3Schema.Cooking.self
    ]

    static var versionIdentifier = Schema.Version(0, 0, 3)

    static func didMigrate(modelContext: ModelContext) throws {
        Log.log("Schema Version Migration 2->3")
    }
}

enum Version4Schema: VersionedSchema {
    static var models: [any PersistentModel.Type] = [
        Version4Schema.Recipe.self,
        Version4Schema.Book.self,
        Version4Schema.Cooking.self,
        Version4Schema.Tag.self
    ]

    static var versionIdentifier = Schema.Version(0, 0, 4)

    /// Introduces sortOrder for 'planned' recipes.
    /// Replicate the current order by doing the alphasort query & labelling them
    static func didMigrate(modelContext: ModelContext) throws {
        let fd = FetchDescriptor(
            predicate: Version4Schema.Recipe.predicate(forLifecycle: .planned),
            sortBy: [.init(\Version4Schema.Recipe.name)]
        )
        let recipes = try modelContext.fetch(fd)

        var sortOrder = UInt(1)
        for recipe in recipes {
            recipe.sortOrder = sortOrder
            sortOrder += 1
        }

        try modelContext.save()

        Log.log("Schema Version Migration 3->4")
    }
}

// MARK: Common

typealias CurrentSchema = Version4Schema

typealias Recipe = CurrentSchema.Recipe
typealias Book = CurrentSchema.Book
typealias Cooking = CurrentSchema.Cooking
typealias Tag = CurrentSchema.Tag

// MARK: Migration Plan

enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [
        Version1Schema.self,
        Version2Schema.self,
        Version3Schema.self,
        Version4Schema.self
    ]

    static var stages: [MigrationStage] = [
        /// Populate `Cooking` on introduction
        .custom(fromVersion: Version1Schema.self,
                toVersion: Version2Schema.self,
                willMigrate: nil,
                didMigrate: Version2Schema.didMigrate),

        /// Populate `Recipe.Lifecycle` on introduction
        .custom(fromVersion: Version2Schema.self,
                toVersion: Version3Schema.self,
                willMigrate: nil,
                didMigrate: Version3Schema.didMigrate),

        /// Populate `Recipe.sortOrder` on introduction
        .custom(fromVersion: Version3Schema.self,
                toVersion: Version4Schema.self,
                willMigrate: nil,
                didMigrate: Version4Schema.didMigrate)

    ]
}
