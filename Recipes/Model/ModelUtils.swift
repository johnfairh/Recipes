//
//  ModelUtils.swift
//  Recipes
//
//  Created by John on 13/02/2025.
//

import SwiftData

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

extension ModelContext {
    func trySave() {
        do {
            try save()
        } catch {
            Log.log("Couldn't save model context: \(error)")
        }
    }
}

import Foundation

func IsPreview() -> Bool {
    ProcessInfo.processInfo.processName == "XCPreviewAgent"
}
