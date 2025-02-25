//
//  Schemas.swift
//  Recipes
//
//  Created by John on 25/02/2025.
//
import SwiftData

enum Version1Schema: VersionedSchema {
    static var models: [any PersistentModel.Type] = [
        Recipe.self,
        Book.self
    ]

    static var versionIdentifier = Schema.Version(0, 0, 1)
}

typealias CurrentSchema = Version1Schema

typealias Recipe = CurrentSchema.Recipe
typealias Book = CurrentSchema.Book

enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [
        Version1Schema.self
    ]

    static var stages: [MigrationStage] = [
    ]
}
