//
//  Recipe.swift
//  Recipes
//
//  Created by John on 13/02/2025.
//

import SwiftData
import Foundation

/// Remove ``flagged``
/// Add ``lifecycle``
extension Version3Schema {
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

        enum Lifecycle: UInt8 {
            case planned = 1
            case pinned = 2
            case library = 3
        }

        /// User importance - default value to satisfy SwiftData upgrade, can't be enum because SwiftData still can't sort by them
        var lifecycleRaw: UInt8 = Lifecycle.library.rawValue

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
            self.lifecycle = .library
        }
    }
}

extension Recipe: JModelObject {}

// MARK: Utilities

import SwiftUI

/// Presentation
extension Recipe {
    /// Brief text describing the recipe's location
    var location: String {
        let pageText: String
        if book.hasPageNumbers {
            pageText = pageNumber.map { ", p\($0)" } ?? ""
        } else {
            pageText = ""
        }
        return book.shortName.trimmingCharacters(in: .whitespaces) + pageText
    }

    /// Long sentence describing servings quantity eg. "Makes 3 servings".
    var servings: String {
        let s: String?
        if kind == .meal {
            s = servingsCount.map { "\($0) serving\($0 == 1 ? "" : "s")" }
        } else {
            s = quantity?.localizedLowercase
        }
        return s.map { "Makes \($0)." } ?? "(no servings info)"
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
            return "a month ago"
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
    func makeImported() {
        lastCookedTime = .importedRecipe
    }

    /// Short label of approximate last-cooked eg "Made last week"
    var lastCookedText: String? {
        switch lastCookedTime {
        case .importedRecipe: return nil
        case .none: return "Not made yet"
        case .some(let date): return "Made \(date.whenWasThis)"
        }
    }

    /// Long sentence of approximate last-cooked eg. "Most recently made last week."
    var lastCookedTextLong: String {
        switch lastCookedTime {
        case .importedRecipe: return "Not sure when last made."
        case .none: return "Not made yet."
        case .some(let date): return "Most recently made \(date.whenWasThis)."
        }
    }

    func updateLastCookedTime() {
        lastCookedTime = .now
    }

    func findLastCookedTime() {
        lastCookedTime = nil
        for cooking in cookings {
            if lastCookedTime == nil || lastCookedTime! < cooking.timestamp {
                lastCookedTime = cooking.timestamp
            }
        }
        Log.log("Recalculated lastCookedTime for '\(name)' to \(lastCookedTime.map { $0.description } ?? "(nil)")")
    }
}

// MARK: Cookings

extension Recipe {
    /// Long sentence of approx first-cooked eg. "First made on 3 September 2012"
    var firstCookedTextLong: String? {
        guard let cooking = cookings.sorted(by: { $0.timestamp < $1.timestamp }).first else {
            return nil
        }
        return "First made on \(cooking.timestamp.formatted(date: .complete, time: .omitted))."
    }
}

// MARK: Lifecycle

extension Recipe {
    var lifecycle: Lifecycle {
        get {
            Lifecycle(rawValue: lifecycleRaw) ?? .library
        }
        set {
            lifecycleRaw = newValue.rawValue
        }
    }
}

extension Recipe.Lifecycle {
    var name: String {
        switch self {
        case .planned: "Planned"
        case .pinned: "Pinned"
        case .library: "Library"
        }
    }
}

// Planning / Pinning / Cooking UI
extension Recipe {
    private var canPlan: Bool { lifecycle != .planned }

    var planActionName: String {
        canPlan ? "Plan" : "Unplan"
    }

    var planActionIconName: String {
        canPlan ? "calendar.badge.plus" : "calendar.badge.minus"
    }

    var planActionNextState: Lifecycle {
        canPlan ? .planned : .library
    }

    private var canPin: Bool { lifecycle != .pinned }

    var pinActionName: String {
        canPin ? "Pin" : "Unpin"
    }

    var pinActionIconName: String {
        canPin ? "pin.fill" : "pin.slash.fill"
    }

    var pinActionNextState: Lifecycle {
        canPin ? .pinned : .library
    }

    var cookActionName: String {
        "Cook"
    }

    var cookActionIconName: String {
        "fork.knife"
    }
}

// MARK: Actions - from UI & intents

extension Recipe {
    func doCookAction(modelContext: ModelContext) {
        Log.log("Update cooked for recipe '\(name)'")
        modelContext.updateModel { _ in
            updateLastCookedTime()
            let cooking = Cooking(recipe: self, notes: nil, timestamp: lastCookedTime)
            modelContext.insert(cooking)
            // implicit unplan/unpin
            lifecycle = .library
        }
    }

    func doPlanAction(modelContext: ModelContext) {
        let next = planActionNextState
        Log.log("Updated recipe '\(name)' to \(next)")
        modelContext.updateModel { _ in
            lifecycle = next
        }
    }

    func doPinAction(modelContext: ModelContext) {
        let next = pinActionNextState
        Log.log("Updated recipe '\(name)' to \(next)")
        modelContext.updateModel { _ in
            lifecycle = next
        }
    }

    func doDeleteAction(modelContext: ModelContext) {
        Log.log("Delete recipe '\(name)'")
        modelContext.updateModel { _ in
            modelContext.delete(self)
        }
    }
}
