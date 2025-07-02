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

    enum TabValue: String {
        case recipes = "Recipes"
        case history = "History"
        case books = "Books"
    }

    var selectedTab: TabValue = .recipes

    // MARK: Recipes Tab

    var selectedRecipe: Recipe? = nil
    var recipeSearchText: String = ""

    // MARK: History Tab
    var historySearchText: String = ""

    init() {
    }
}
