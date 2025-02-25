//
//  Recipe.swift
//  Recipes
//
//  Created by John on 13/02/2025.
//

import SwiftData
import Foundation

@Model
class Recipe {
    /// Timestamp
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

    /// Freeform
    var notes: String

    init(name: String, book: Book, pageNumber: UInt?, url: String?, kind: Kind, servingsCount: UInt?, quantity: String?, notes: String) {
        self.creationTime = Date.now
        self.name = name
        self.book = book
        self.pageNumber = pageNumber
        self.url = url
        self.kind = kind
        self.servingsCount = servingsCount
        self.quantity = quantity
        self.notes = notes
    }
}

/// Presentation
extension Recipe {
    /// Text describing the recipe's location
    var location: String {
        let pageText = pageNumber.map { ", p\($0)" } ?? ""
        return book.shortName + pageText
    }

    /// Text describing servings
    var servings: String? {
        servingsCount.map { "\($0) serving\($0 == 1 ? "" : "s")" }
    }

    /// Brief summary for list view
    var summary: String {
        var summary = location
        if let servings {
            summary += ", \(servings)"
        }
        return summary
    }

    /// System image name
    var symbolName: String {
        switch kind {
        case .meal: return "carrot"
        case .sweet: return "birthday.cake"
        case .other: return "popcorn"
        }
    }
}
