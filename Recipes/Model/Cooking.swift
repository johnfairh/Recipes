//
//  Cooking.swift
//  Recipes
//
//  Created by John on 27/03/2025.
//

import SwiftData
import Foundation

/// No changes but need a separate class otherwise SwiftData crashes CoreData.
extension Version3Schema {
    @Model
    class Cooking {
        /// When did it happen
        @Attribute(.unique)
        var timestamp: Date

        /// What was it
        var recipe: Recipe

        /// Any thoughts?
        var notes: String?

        init(recipe: Recipe, notes: String?, timestamp: Date? = nil) {
            self.timestamp = timestamp ?? .now
            self.recipe = recipe
            self.notes = notes
        }

        @Transient
        private var _monthCode: Int? = nil
    }
}

// MARK: MonthCode - for sectioning in the UI

extension Cooking {
    var monthCode: Int {
        if let _monthCode { return _monthCode }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: timestamp)

        let mc = components.year! * 100 + components.month!
        _monthCode = mc
        return mc
    }
}

extension Int {
    var decodeMonthCode: String {
        let year = self / 100
        let month = self % 100
        return "\(Calendar.current.monthSymbols[month - 1]) \(year)"
    }
}

// MARK: Verbs

extension Cooking {
    func doDeleteAction(modelContext: ModelContext) {
        Log.log("Delete cooking for '\(recipe.name)' at \(timestamp)")
        modelContext.updateModel { _ in
            modelContext.delete(self)
        }
    }
}
