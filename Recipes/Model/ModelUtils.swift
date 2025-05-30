//
//  ModelUtils.swift
//  Recipes
//
//  Created by John on 13/02/2025.
//

import SwiftData

// MARK: ModelObject - SortOrder support

protocol WithSortOrder {
    var sortOrder: UInt { get }
}

extension WithSortOrder {
    static func nextSortOrder(all: [Self]) -> UInt {
        all.reduce(0) { soFar, next in
            return max(soFar, next.sortOrder)
        } + 1
    }
}

extension WithSortOrder where Self: PersistentModel {
    static func nextSortOrder(modelContext: ModelContext) -> UInt {
        var fd = FetchDescriptor<Self>(sortBy: [.init(\.sortOrder, order: .reverse)])
        fd.fetchLimit = 1

        do {
            let results = try modelContext.fetch(fd)
            if let val = results.first {
                return val.sortOrder + 1
            }
        } catch {
            // doomed
            Log.log("Couldn't fetch for sortorder: \(error)")
        }
        return 0
    }
}

// MARK: ModelObject - fetchability

protocol JModelObject: PersistentModel {
    var name: String { get }
}

extension JModelObject {
    static func find(name: String, modelContext: ModelContext) throws -> Self? {
        var fetchDescriptor = FetchDescriptor<Self>(
            predicate: #Predicate { $0.name == name }
        )
        fetchDescriptor.fetchLimit = 1
        return try modelContext.fetch(fetchDescriptor).first
    }

    static func find(names: [String], modelContext: ModelContext) throws -> [Self] {
        let fetchDescriptor = FetchDescriptor<Self>(
            predicate: #Predicate { names.contains($0.name) } /* XXX sortorder */
        )
        return try modelContext.fetch(fetchDescriptor)
    }

    static func all(modelContext: ModelContext) throws -> [Self] {
        let fd = FetchDescriptor<Self>() /* XXX sortorder (sortBy: [.init(\.sortOrder)]) */
        return try modelContext.fetch(fd)
    }
}


// MARK: ModelContext helpers

extension ModelContext {
    func trySave() {
        do {
            try save()
        } catch {
            Log.log("Couldn't save model context: \(error)")
        }
    }
}

extension ModelContext {
    func undo() {
        undoManager?.undo()
    }
}

import WidgetKit

extension ModelContext {
    func notifyWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

import AppIntents

extension ModelContext {
    /// Take an Entity, find the corresponding modelobject, do a thing, then save the DB and notify everyone who might care
    @discardableResult
    func updateModel<ModelType, EntityType, R>(forEntity entity: EntityType, as modelType: ModelType.Type, modify: (ModelContext, ModelType) async throws -> R) async throws -> R where ModelType: JModelObject, EntityType: AppEntity, EntityType.ID == String {
        guard let m = try ModelType.find(name: entity.id, modelContext: self) else {
            throw AppIntentError.Unrecoverable.entityNotFound
        }
        let result = try await modify(self, m)
        trySave()
        notifyWidgets()
        return result
    }

    /// Do an action on the model with propagation
    @discardableResult
    func updateModel<ModelType, R>(_ model: ModelType, modify: () throws -> R) rethrows -> R where ModelType: JModelObject {
        let result = try modify()
        trySave()
        notifyWidgets()
        return result
    }
}

// MARK: Misc Stuff To Be Moved

import Foundation

func IsPreview() -> Bool {
    ProcessInfo.processInfo.processName == "XCPreviewAgent"
}

extension String {
    var emptyNil: String? {
        isEmpty ? nil : self
    }
}
