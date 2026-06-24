//
//  RecipeShortcuts.swift
//  Recipes
//
//  Created by John on 24/06/2026.
//

import AppIntents

final class AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RecipeCookIntent(),
            phrases: [
                "Cook in \(.applicationName)"
            ],
            shortTitle: "Cook a recipe",
            systemImageName: "fork.knife"
        )
        AppShortcut(
            intent: RecipePlanIntent(),
            phrases: [
                "Plan in \(.applicationName)"
            ],
            shortTitle: "Plan a recipe",
            systemImageName: "calendar.badge.minus"
        )
        AppShortcut(intent: RecipeFromURLIntent(),
                    phrases: [
                        "Create recipe in \(.applicationName)"
                    ],
                    shortTitle: "Create a recipe from a web page",
                    systemImageName: "fork.knife.circle"
        )
    }
}
