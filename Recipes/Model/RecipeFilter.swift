//
//  RecipeFilter.swift
//  Recipes
//
//  Created by John on 24/06/2025.
//

import Foundation

struct RecipeFilter: Identifiable {
    let id = UUID()

    enum Kind {
        case name // regex
        case book // book
        case url // regex
        case kind // R.K
        case servings // Int quantity, Bool exact
        case quantity// regex
        case neverCooked // nil
        case importedCooked // nil
        case cookedSince // Date
        case notes // regex
    }
    var kind: Kind

    // Filter properties - have to be un-unioned for SwiftUI bindings
    var regex: any RegexComponent
    var regexView: String

    // var book: Book // ? grumble
    // var kind: Recipe.Kind
    // var count: Int
    // var exact: Bool
    // var date: Date

    var includeNotExclude: Bool

    init(kind: Kind) {
        self.kind = kind
        self.regex = #//#
        self.regexView = ""
        self.includeNotExclude = true
    }

    static var sample: RecipeFilter {
        .init(kind: .name)
    }
}

struct RecipeFilterList {
    var filters: [RecipeFilter]
    var allNotAny: Bool

    static var sample: RecipeFilterList {
        .init(filters: [.sample], allNotAny: true)
    }
}

// MARK: Filter Pass

extension RecipeFilter {
    private func passCore(recipe: Recipe) -> Bool {
        switch kind {
        case .name:
            return recipe.name.contains(regex)
        case .book:
            preconditionFailure()
//            return recipe.book == book
        case .url:
            return recipe.url?.contains(regex) ?? false
        case .kind:
            preconditionFailure()
//            return recipe.kind == kind
        case .servings:
//            guard let servingsCount = recipe.servingsCount else {
//                return false
//            }
            preconditionFailure()
//            if exact {
//                return servingsCount == count
//            }
//            return servingsCount >= count
        case .quantity:
            return recipe.quantity?.contains(regex) ?? false
        case .neverCooked:
            return recipe.lastCookedTime == nil
        case .importedCooked:
            return recipe.lastCookedTime == .importedRecipe
        case .cookedSince:
//            guard let lastCookedTime = recipe.lastCookedTime else {
//                return false
//            }
            preconditionFailure()
//            return lastCookedTime >= date
        case .notes:
            return recipe.notes.contains(regex)
        }
    }

    func pass(recipe: Recipe) -> Bool {
        passCore(recipe: recipe) == includeNotExclude
    }
}

extension RecipeFilterList {
    func pass(recipe: Recipe) -> Bool {
        for filter in filters {
            let pass = filter.pass(recipe: recipe)
            if pass && !allNotAny {
                return true
            }
            if !pass && allNotAny {
                return false
            }
        }

        return allNotAny
    }
}
