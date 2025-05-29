//
//  RecipesWidget.swift
//  RecipesWidget
//
//  Created by John on 28/05/2025.
//

import WidgetKit
import SwiftUI
import SwiftData

/// Plain data model of the info to display in the widget
///
/// For us this is the entire list of 'planned' recipes, sorted by name
struct PlannedRecipes: TimelineEntry {
    let date: Date

    final class PlannedRecipe: Identifiable {
        let name: String
        let source: String
        let swiftDataId: PersistentIdentifier? // nil for fake data
        let id: UUID

        init(name: String, source: String) {
            self.name = name
            self.source = source
            self.swiftDataId = nil
            self.id = UUID()
        }

        init(_ recipe: Recipe) {
            self.name = recipe.name
            self.source = recipe.location
            self.swiftDataId = recipe.id
            self.id = UUID()
        }
    }
    let recipes: [PlannedRecipe]

    init(recipes: [PlannedRecipe]) {
        self.date = .now
        self.recipes = recipes
    }

    /// Dummy data used in "the widget gallery"
    static var placeholder: PlannedRecipes {
        let recipes = [
            PlannedRecipe(name: "Chilli con Carne", source: "Purple book, page 94"),
            PlannedRecipe(name: "Best Chocolate Brownies", source: "Smitten Kitchen #1, page 108"),
            PlannedRecipe(name: "Worst Chocolate Brownies", source: "Smitten Kitchen #1, page 109")

        ]
        return PlannedRecipes(recipes: recipes)
    }

    /// Dummy data used in "the widget gallery"
    static var empty: PlannedRecipes {
        PlannedRecipes(recipes: [])
    }

    /// Actually query swiftdata and build the list
    init(modelContext: ModelContext) {
        var fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Recipe.name, order: .forward)])
        let plannedRawValue = Recipe.Lifecycle.planned.rawValue
        fetchDescriptor.predicate = #Predicate { $0.lifecycleRaw == plannedRawValue }

        if let recipeModels = try? modelContext.fetch(fetchDescriptor) {
            self.init(recipes: recipeModels.map(PlannedRecipe.init))
        } else {
            self = .placeholder
        }
    }
}

/// Glue to generate `PlannedRecipes`
///
/// Our widget data is not time-related so we just return this stuff and rely on the app to refresh it
struct PlannedRecipesProvider: TimelineProvider {
    func placeholder(in context: Context) -> PlannedRecipes {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (PlannedRecipes) -> ()) {
        completion(.placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlannedRecipes>) -> ()) {
        let modelContainer = DatabaseLoader.minimalModelContainer
        let modelContext = ModelContext(modelContainer)
        let plannedRecipes = PlannedRecipes(modelContext: modelContext)
        // policy .never means app prompts refresh
        let timeline = Timeline(entries: [plannedRecipes], policy: .never)
        completion(timeline)
    }
}

/// UI - this is fairly horrible, really just designing for the case I want of the 'medium' widget.
/// We have a fairly grotty task of fitting a variable length list of things into a (small) fixed-size
/// area... don't mention dynamic type...
struct RecipesWidgetEntryView : View {
    @Environment(\.widgetFamily) var widgetFamily

    var maxRows: Int {
        switch widgetFamily {
        case .systemMedium: return 2
        case .systemLarge: return 4
        default: return 1
        }
    }

    let recipes: PlannedRecipes

    var displayCount: Int {
        min(maxRows, recipes.recipes.count)
    }

    var displayRecipes: [PlannedRecipes.PlannedRecipe] {
        Array(recipes.recipes[0..<displayCount])
    }

    var lastId: UUID {
        recipes.recipes[displayCount - 1].id
    }

    var body: some View {
        if recipes.recipes.isEmpty {
            VStack {
                Image("RecipesAppIcon")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Text("No cooking planned")
                    .foregroundColor(.white)
            }
        } else {
            VStack(alignment: .leading) {
                ForEach(displayRecipes) { recipe in
                    RecipeLineView(recipe: recipe)
                    if recipe.id != lastId {
                        Divider()
                    }
                }
                if displayCount < recipes.recipes.count {
                    Spacer()
                    Text("more...")
                        .font(.footnote)
                        .fontWeight(.light)
                        .foregroundColor(.white)
                        .padding([.leading], 4)
                }
            }
        }
    }
}

struct RecipeLineView: View {
    let recipe: PlannedRecipes.PlannedRecipe

    var lessBright: Color = {
        Color(red: 0.9, green: 0.9, blue: 0.9)
    }()

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                Text(recipe.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text(recipe.source)
                    .font(.subheadline)
                    .fontWeight(.light)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button(action: {}, label: {
                Image(systemName: "fork.knife").foregroundColor(lessBright)
            })
            Button(action: {}, label: {
                Image(systemName: "calendar.badge.minus").foregroundColor(lessBright)
            })
        }.padding(4)
    }
}

/// System glue
struct RecipesWidget: Widget {
    let kind: String = "RecipesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PlannedRecipesProvider()) { entry in
            RecipesWidgetEntryView(recipes: entry)
                .containerBackground(.linearGradient(Color("WidgetBackground").gradient, startPoint: .bottom, endPoint: .top), for: .widget)
                .tint(Color("AccentColor"))
        }
        .configurationDisplayName("Recipes Widget")
        .description("Manage planned recipes.")
        .supportedFamilies([.systemMedium, .systemLarge, .systemExtraLarge])
    }
}

#Preview(as: .systemMedium) {
    RecipesWidget()
} timeline: {
    PlannedRecipes.empty
    PlannedRecipes.placeholder
}

#Preview(as: .systemLarge) {
    RecipesWidget()
} timeline: {
    PlannedRecipes.empty
    PlannedRecipes.placeholder
}
