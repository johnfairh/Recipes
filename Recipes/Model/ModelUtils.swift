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
    /// Find an object by name in the DB.  Nil if not found; throws on DB error.
    static func find(name: String, modelContext: ModelContext) throws -> Self? {
        var fetchDescriptor = FetchDescriptor<Self>(
            predicate: #Predicate { $0.name == name }
        )
        fetchDescriptor.fetchLimit = 1
        return try modelContext.fetch(fetchDescriptor).first
    }

    /// FInd a set of models - order undefined?
    static func find(names: [String], modelContext: ModelContext) throws -> [Self] {
        let fetchDescriptor = FetchDescriptor<Self>(
            predicate: #Predicate { names.contains($0.name) } /* XXX sortorder */
        )
        return try modelContext.fetch(fetchDescriptor)
    }

    /// Find all models
    static func all(modelContext: ModelContext) throws -> [Self] {
        let fd = FetchDescriptor<Self>() /* XXX sortorder (sortBy: [.init(\.sortOrder)]) */
        return try modelContext.fetch(fd)
    }

    /// Find an object from its entity.  Throws on DB error and notfound.
    static func find<EntityType>(entity: EntityType, modelContext: ModelContext) throws -> Self where EntityType: AppEntity, EntityType.ID == String {
        if let model = try find(name: entity.id, modelContext: modelContext) {
            return model
        }
        throw AppIntentError.Unrecoverable.entityNotFound
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
    /// Do an action on the model with propagation
    @discardableResult
    func updateModel<R>(_ modify: (ModelContext) throws -> R) rethrows -> R {
        let result = try modify(self)
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
