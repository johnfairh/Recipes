//
//  CreateEditRecipeView.swift
//  Recipes
//
//  Created by John on 27/05/2025.
//

import SwiftUI
import SwiftData

struct CreateEditRecipeView: View {
    @Environment(\.dismiss) private var dismiss

    @FocusState private var onAppearFocus: Bool

    private var modelContext: ModelContext
    private let books: [Book]

    @Bindable var recipe: Recipe
    @State var isBrandNew = true

    let isCreate: Bool
    var sheetTitle: String {
        isCreate ? "New Recipe" : "Edit Recipe"
    }

    init(parentModelContext: ModelContext, recipe: Recipe? = nil) {
        modelContext = ModelContext(parentModelContext.container)
        modelContext.autosaveEnabled = false
        if let recipe {
            self.recipe = modelContext.model(for: recipe.id) as! Recipe
            isCreate = false
        } else {
            self.recipe = Recipe(name: "", book: .dummy, pageNumber: nil, url: nil, kind: .meal, servingsCount: nil, quantity: nil, isImported: false, notes: "")
            isCreate = true
        }

        books = try! modelContext.fetch(
            FetchDescriptor<Book>(sortBy: [.init(\Book.sortOrder)])
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Name", text: $recipe.name)
                        .focused($onAppearFocus)
                }

                Section("Details") {
                    Picker("Type", selection: $recipe.kind) {
                        Text("Meal").tag(Recipe.Kind.meal)
                        Text("Sweet").tag(Recipe.Kind.sweet)
                        Text("Other").tag(Recipe.Kind.other)
                    }
                    if recipe.kind == .meal {
                        Picker("Servings", selection: $recipe.servingsCount) {
                            ForEach(UInt(1)..<7, id: \.self) { count in
                                Text(count.description).tag(count)
                            }
                        }
                    } else {
                        LabeledContent {
                            TextField("Quantity", text: .emptyNilString($recipe.quantity))
                                .multilineTextAlignment(.trailing)
                        } label: {
                            Text("Makes")
                        }
                    }
                }

                Section("Source") {
                    Picker("Book", selection: $recipe.book) {
                        ForEach(books) { book in
                            Text(book.shortName).tag(book)
                        }
                    }
                    if recipe.book.hasPageNumbers {
                        LabeledContent {
                            TextField("#", value: $recipe.pageNumber, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)

                        } label: {
                            Text("Page number")
                        }
                    }
                    LabeledContent {
                        TextField("URL", text: .emptyNilString($recipe.url))
                            .multilineTextAlignment(.trailing)
                    } label: {
                        Text("URL")
                    }
                }

                if isCreate {
                    Section {
                        Toggle("Brand new recipe", isOn: $isBrandNew)
                    } header: {
                        Text("Special")
                    } footer: {
                        Text("Turn this off if you're adding a recipe that has been cooked before.")
                    }
                }

                Section("Notes") {
                    MultiLineTextField(text: $recipe.notes, prompt: "Notes", minHeight: 80)
                }
            }
            .navigationTitle(sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark", role: .confirm) {
                        saveRecipe()
                        dismiss()
                    }
                    .bold()
                    .disabled(isInvalid)
                }
            }
        }
        .onAppear {
            onAppearFocus = true
            if isCreate, let firstBook = books.first {
                recipe.book = firstBook
            }
        }
    }

    private var isInvalid: Bool {
        recipe.name.isEmpty ||
        (recipe.book.hasPageNumbers && recipe.pageNumber == nil)
    }

    private func saveRecipe() {
        if isCreate {
            Log.log("Create recipe '\(recipe.name)'")
            if !isBrandNew {
                recipe.makeImported()
            }
            modelContext.insert(recipe)
        } else {
            Log.log("Commit changes to recipe '\(recipe.name)'")
        }
        modelContext.trySave()
    }
}

struct CreateRecipeWrapperView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        CreateEditRecipeView(parentModelContext: modelContext)
    }
}

#Preview(traits: .previewObjects) {
    CreateRecipeWrapperView()
}
