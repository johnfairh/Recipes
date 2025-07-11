//
//  RecipesWidget.swift
//  RecipesWidget
//
//  Created by John on 28/05/2025.
//

import WidgetKit
import SwiftUI
import SwiftData

extension RecipeEntity {
    init(name: String, location: String, fakeUuid: String) {
        self.id = fakeUuid
        self.name = name
        self.location = location
    }
}

/// Plain data model of the info to display in the widget
///
/// For us this is the entire list of 'planned' recipes, sorted by name
struct PlannedRecipes: TimelineEntry {
    let date: Date
    let recipes: [RecipeEntity]

    init(recipes: [RecipeEntity]) {
        self.date = .now
        self.recipes = recipes
    }

    /// Dummy data used in "the widget gallery"
    static var placeholder: PlannedRecipes {
        let recipes = [
            RecipeEntity(name: "Chilli con Carne", location: "Purple book, page 94", fakeUuid: "0"),
            RecipeEntity(name: "Best Chocolate Brownies", location: "Smitten Kitchen #1, page 108", fakeUuid: "1"),
            RecipeEntity(name: "Worst Chocolate Brownies", location: "Smitten Kitchen #1, page 109", fakeUuid: "2")
        ]
        return PlannedRecipes(recipes: recipes)
    }

    /// Dummy data used in "the widget gallery"
    static var empty: PlannedRecipes {
        PlannedRecipes(recipes: [])
    }

    /// Actually query swiftdata and build the list
    init(modelContext: ModelContext) {
        var fetchDescriptor = FetchDescriptor(sortBy: [
            SortDescriptor(\Recipe.sortOrder, order: .forward),
            SortDescriptor(\Recipe.name, order: .forward)
        ])
        fetchDescriptor.predicate = Recipe.predicate(forLifecycle: .planned)

        if let recipeModels = try? modelContext.fetch(fetchDescriptor) {
            self.init(recipes: recipeModels.map(RecipeEntity.init))
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

    var displayRecipes: [RecipeEntity] {
        Array(recipes.recipes[0..<displayCount])
    }

    var lastId: String {
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
    let recipe: RecipeEntity

    var lessBright: Color = {
        Color(red: 0.9, green: 0.9, blue: 0.9)
    }()

    var recipeURL: URL {
        if let encodedName = recipe.name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
           let url = URL(string: "widget:///\(encodedName)") {
            return url
        }
        return URL(string: "widget:///")!
    }

    var body: some View {
        HStack(alignment: .center) {
            Link(destination: recipeURL) {
                VStack(alignment: .leading) {
                    Text(recipe.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(recipe.location)
                        .font(.subheadline)
                        .fontWeight(.light)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            if recipe.id == recipe.name { // fake UUID placeholder
                Button(intent: RecipeCookIntent(recipe: recipe), label: {
                    Image(systemName: "fork.knife").foregroundColor(lessBright)
                })
                Button(intent: RecipePlanIntent(recipe: recipe), label: {
                    Image(systemName: "calendar.badge.minus").foregroundColor(lessBright)
                })
            }
        }.padding(4)
    }
}

/// System glue
struct RecipesWidget: Widget {
    let kind: String = "RecipesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PlannedRecipesProvider()) { entry in
            RecipesWidgetEntryView(recipes: entry)
                .containerBackground(.linearGradient(Color("WidgetBackground").gradient, startPoint: .top, endPoint: .bottom), for: .widget)
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
