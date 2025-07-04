//
//  UIState.swift
//  Recipes
//
//  Created by John on 01/07/2025.
//

import Observation

@Observable
class UIState {

    // MARK: Tabs

    enum TabValue: String, CaseIterable {
        case recipes = "Recipes"
        case history = "History"
        case books = "Books"
    }

    var selectedTab: TabValue = .recipes

    // MARK: Recipes Tab

    @Observable
    class RecipesTab {
        var selected: Recipe? = nil
        var searchText = ""

        enum Sheet {
            case create
            case filter
        }
        var sheet: Sheet? = nil

        var filterList: RecipeFilterList? = nil

        init() {}
    }
    let recipesTab = RecipesTab()

    // MARK: History Tab

    @Observable
    class HistoryTab {
        var searchText = ""

        init() {}
    }
    let historyTab = HistoryTab()

    // MARK: Books Tab

    @Observable
    class BooksTab {
        var selected: Book? = nil

        enum Sheet {
            case create
            case log
        }
        var sheet: Sheet? = nil

        init() {}
    }
    let booksTab = BooksTab()

    init() {
    }
}


// MARK: Navigation helpers

extension UIState {
    func show(recipe: Recipe) {
        selectedTab = .recipes
        recipesTab.selected = recipe
    }

    // XXX hmm could do with exact match...
    func showHistory(for recipe: Recipe) {
        selectedTab = .history
        historyTab.searchText = recipe.name
    }
}
