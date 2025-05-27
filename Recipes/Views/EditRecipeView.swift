//
//  EditRecipeView.swift
//  Recipes
//
//  Created by John on 27/05/2025.
//

import SwiftUI
import SwiftData

struct EditRecipeView: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Book.sortOrder) private var books: [Book]

    @FocusState private var onAppearFocus: Bool

    private var modelContext: ModelContext
    @Bindable var recipe: Recipe

    init(recipe: Recipe, modelContainer: ModelContainer) {
        modelContext = ModelContext(modelContainer)
        modelContext.autosaveEnabled = false
        self.recipe = modelContext.model(for: recipe.id) as! Recipe
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $recipe.name)
                        .focused($onAppearFocus)
                }

//                Section {
//                    Picker("Type", selection: $kind) {
//                        Text("Meal").tag(Recipe.Kind.meal)
//                        Text("Sweet").tag(Recipe.Kind.sweet)
//                        Text("Other").tag(Recipe.Kind.other)
//                    }
//                    if kind == .meal {
//                        Picker("Servings", selection: $servings) {
//                            ForEach(UInt(1)..<7, id: \.self) { count in
//                                Text(count.description).tag(count)
//                            }
//                        }
//                    } else {
//                        TextField("Quantity", text: $quantity)
//                    }
//                }
//
//                Section {
//                    Picker("Book", selection: $book) {
//                        ForEach(books) { book in
//                            Text(book.shortName).tag(book)
//                        }
//                    }
//                    if let book, book.hasPageNumbers {
//                        TextField("Page number", value: $pageNumber, formatter: NumberFormatter())
//                            .keyboardType(.numberPad)
//                    }
//                    TextField("URL", text: $url)
//                }
//
//                Section {
//                    Toggle("Brand new recipe", isOn: $isBrandNew)
//                }
//
//                Section {
//                    TextField("Notes", text: $notes)
//                }
            }
            .navigationTitle("Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveRecipe()
                        dismiss()
                    }
                    .bold()
//                    .disabled(isInvalid)
                }
            }
        }
        .onAppear {
            onAppearFocus = true
//            book = books.first
        }
    }

//    private var isInvalid: Bool {
//        guard let book else {
//            return true
//        }
//
//        return name.isEmpty ||
//               (book.hasPageNumbers && pageNumber == nil)
//    }

    private func saveRecipe() {
        modelContext.trySave()
    }
//    private func createNewRecipe() {
//        Log.log("Create recipe '\(name)'")
//        let recipe = Recipe(
//            name: name,
//            book: book!,
//            pageNumber: pageNumber,
//            url: url.emptyNil,
//            kind: kind,
//            servingsCount: servings,
//            quantity: quantity.emptyNil,
//            isImported: !isBrandNew,
//            notes: notes
//        )
//        modelContext.insert(recipe)
//        modelContext.trySave()
//    }
}

//#Preview(traits: .previewObjects) {
//}
