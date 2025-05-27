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
    }
}
