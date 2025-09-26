//
//  Book.swift
//  Recipes
//
//  Created by John on 13/02/2025.
//

import SwiftData

extension CurrentSchema {
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

        static let dummy = Book(shortName: "", longName: "", symbolName: "", hasPageNumbers: false, sortOrder: 0)
    }
}

// MARK: Extensions

extension Book: WithSortOrder {}

extension Book {
    static let symbolNames = [
        "book.closed",
        "brain.head.profile",
        "network",
        "book.pages",
        "book",
        "text.book.closed"
    ]

    static let defaultSymbolName = symbolNames[0]
}

extension Book: JModelObject {
    var name: String { shortName }
}
