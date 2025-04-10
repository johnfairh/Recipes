//
//  Recipe.swift
//  Recipes
//
//  Created by John on 13/02/2025.
//

import SwiftData
import Foundation

/// Add ``cookings``
/// Remove ``what`` (oops)
/// Add ``flagged``
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

// MARK: Utilities

/// Presentation
extension Recipe {
    /// Text describing the recipe's location
    var location: String {
        let pageText = pageNumber.map { ", p\($0)" } ?? ""
        return book.shortName.trimmingCharacters(in: .whitespaces) + pageText
    }

    /// Text describing servings
    var servings: String? {
        quantity ?? servingsCount.map { "\($0) serving\($0 == 1 ? "" : "s")" }
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

// MARK: Last-cooked time

extension Date {
    static let importedRecipe = Date.distantPast

    // I cannot figure out how to do this with the modern swift formatter, docs
    // make me want to punch someone
    static var spellOutFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .spellOut
        return numberFormatter
    }()

    private func spellOut(_ number: Int) -> String {
        Self.spellOutFormatter.string(from: number as NSNumber)!
    }

    var whenWasThis: String {
        let calendar = Calendar.current
        let interval = calendar.dateComponents([.year, .month, .day], from: self, to: .now)

        let year = interval.year ?? 0
        let month = interval.month ?? 0
        let day = interval.day ?? 0

        if year > 0 {
            return "more than a year ago"
        }
        if month > 1 {
            return spellOut(month) + " months ago"
        }
        if month == 1 {
            return "last month"
        }
        if day > 14 {
            return spellOut(day / 7) + " weeks ago"
        }
        if day >= 7 {
            return "last week"
        }
        if day > 1 {
            return spellOut(day) + " days ago"
        }
        if day == 1 {
            return "yesterday"
        }
        return "today"
    }
}

extension Recipe {
    var lastCookedText: String? {
        switch lastCookedTime {
        case .importedRecipe: return nil
        case .none: return "Not made yet"
        case .some(let date): return "Made \(date.whenWasThis)"
        }
    }

    var actualLastCookedTime: Date? {
        switch lastCookedTime {
        case .none, .importedRecipe: return nil
        case .some(let date): return date
        }
    }

    func updateLastCookedTime() {
        lastCookedTime = .now
    }
}
