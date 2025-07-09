//
//  RecipeFilter.swift
//  Recipes
//
//  Created by John on 24/06/2025.
//

import Foundation

struct RecipeFilter: Identifiable {
    let id = UUID()

    enum Kind: String, CaseIterable, Identifiable {
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

        var id: String { self.rawValue }
    }
    var kind: Kind

    // Filter properties - have to be un-unioned for SwiftUI bindings
    var regex: any RegexComponent
    var regexView: String

    var book: Book?
    var recipeKind: Recipe.Kind
    var count: Int
    var exact: Bool
    var date: Date

    var includeNotExclude: Bool

    init(kind: Kind) {
        self.kind = kind
        self.regex = #//#
        self.regexView = ""
        self.includeNotExclude = true
        self.recipeKind = .meal
        self.date = Date()
        self.count = 1
        self.exact = true
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

    static var empty: RecipeFilterList {
        .init(filters: [], allNotAny: true)
    }
}

// MARK: UI

extension RecipeFilter.Kind {
    var label: String {
        switch self {
        case .name: return "Name like"
        case .book: return "Book"
        case .url: return "URL like"
        case .kind: return "Kind"
        case .servings: return "Servings"
        case .quantity: return "Quantity like"
        case .neverCooked: return "Never been cooked"
        case .importedCooked: return "Imported"
        case .cookedSince: return "Cooked since"
        case .notes: return "Notes like"
        }
    }
}

// MARK: Recipe Pass/Fail Filter

extension RecipeFilter {
    private func passCore(recipe: Recipe) -> Bool {
        switch kind {
        case .name:
            return recipe.name.contains(regex)
        case .book:
            return recipe.book == book
        case .url:
            return recipe.url?.contains(regex) ?? false
        case .kind:
            return recipe.kind == recipeKind
        case .servings:
            guard let servingsCount = recipe.servingsCount else {
                return false
            }
            if exact {
                return servingsCount == count
            }
            return servingsCount >= count
        case .quantity:
            return recipe.quantity?.contains(regex) ?? false
        case .neverCooked:
            return recipe.lastCookedTime == nil
        case .importedCooked:
            return recipe.lastCookedTime == .importedRecipe
        case .cookedSince:
            guard let lastCookedTime = recipe.lastCookedTime else {
                return false
            }
            return lastCookedTime >= date
        case .notes:
            return recipe.notes.contains(regex)
        }
    }

    func pass(recipe: Recipe) -> Bool {
        passCore(recipe: recipe) == includeNotExclude
    }

// Predicates - to execute the filter in the database.
// Doesn't work because weirdly there is no "compound predicate" technology,
// can't AND and NOT these things.
//
//    private var predicateCore: Predicate<Recipe> {
//        switch kind {
//        case .name:
//            return #Predicate { $0.name.contains(regex) }
//        case .book:
//            return #Predicate { $0.book == book }
//        case .url:
//            return #Predicate { $0.url?.contains(regex) ?? false }
//        case .kind:
//            return #Predicate { $0.kind == recipeKind }
//        case .servings:
//            return #Predicate { recipe in
//                recipe.servingsCount != nil &&
//                ((exact && (recipe.servingsCount! == count)) ||
//                 (!exact && (recipe.servingsCount! >= count)))
//            }
//        case .quantity:
//            return #Predicate { $0.quantity?.contains(regex) ?? false }
//        case .neverCooked:
//            return #Predicate { $0.lastCookedTime == nil }
//        case .importedCooked:
//            return #Predicate { $0.lastCookedTime == Date.importedRecipe }
//        case .cookedSince:
//            return #Predicate { recipe in
//                (recipe.lastCookedTime != nil) &&
//                (recipe.lastCookedTime! >= date)
//            }
//        case .notes:
//            return #Predicate { $0.notes.contains(regex) }
//        }
//    }
//
//    var predicate: Predicate<Recipe> {
//        let p = predicateCore
//        return includeNotExclude ? p : p.inverted
//    }
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
