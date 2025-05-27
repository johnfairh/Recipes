//
//  Version2Models.swift
//  Recipes
//
//  Created by John on 27/05/2025.
//

import SwiftData
import Foundation

extension Version2Schema {
    @Model
    class Recipe {
        /// Timestamp of this objects
        var creationTime: Date

        /// Name, possibly longish
        var name: String

        /// Location
        var book: Book
        var pageNumber: UInt?
        var url: String?

        enum Kind: Int, Codable {
            case meal = 1
            case sweet = 2
            case other = 3
        }

        /// Properties
        var kind: Kind
        var servingsCount: UInt?
        var quantity: String?

        /// Last-cooked timestamp; `nil` for never, `.importedRecipe` for something imported from paper records
        var lastCookedTime: Date?

        /// Freeform
        var notes: String

        /// Cooking history
        @Relationship(deleteRule: .cascade, inverse: \Cooking.recipe) var cookings: [Cooking]

        /// Flagged by user (default value here otherwise SwiftData craps out)
        var flagged: Bool = false

        init(name: String, book: Book, pageNumber: UInt?, url: String?, kind: Kind, servingsCount: UInt?, quantity: String?, isImported: Bool, notes: String) {
            self.creationTime = Date.now
            self.name = name
            self.book = book
            self.pageNumber = pageNumber
            self.url = url
            self.kind = kind
            self.servingsCount = servingsCount
            self.quantity = quantity
            self.lastCookedTime = isImported ? .importedRecipe : nil
            self.notes = notes
            self.cookings = []
            self.flagged = false
        }
    }
}

extension Version2Schema.Recipe {
    var actualLastCookedTime: Date? {
        switch lastCookedTime {
        case .none, .importedRecipe: return nil
        case .some(let date): return date
        }
    }
}

extension Version2Schema {
    @Model
    class Book {
        /// Brief name for xref elsewhere
        var shortName: String

        /// Longer descriptive text/name
        var longName: String

        /// Name of the SF Symbol for the Book
        var symbolName: String

        /// Does this book have page numbers?
        var hasPageNumbers: Bool

        /// Contents
        @Relationship(deleteRule: .cascade, inverse: \Recipe.book) var recipes: [Recipe]

        /// UI sort order
        @Attribute(.unique)
        var sortOrder: UInt

        init(shortName: String, longName: String, symbolName: String, hasPageNumbers: Bool, sortOrder: UInt) {
            self.shortName = shortName
            self.longName = longName
            self.symbolName = symbolName
            self.hasPageNumbers = hasPageNumbers
            self.recipes = []
            self.sortOrder = sortOrder
        }
    }
}

extension Version2Schema {
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
