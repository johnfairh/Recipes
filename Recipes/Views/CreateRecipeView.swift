//
//  CreateRecipeView.swift
//  Recipes
//
//  Created by John on 14/02/2025.
//

import SwiftUI
import SwiftData

struct CreateRecipeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Book.sortOrder) private var books: [Book]

    @FocusState private var onAppearFocus: Bool

    @State var name: String = ""
    @State var book: Book?
    @State var pageNumber: UInt? = nil
    @State var url: String = ""
    @State var kind: Recipe.Kind = .meal
    @State var servings: UInt = 1
    @State var quantity: String = ""
    @State var isBrandNew: Bool = false // true
    @State var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .focused($onAppearFocus)
                }

                Section {
                    Picker("Type", selection: $kind) {
                        Text("Meal").tag(Recipe.Kind.meal)
                        Text("Sweet").tag(Recipe.Kind.sweet)
                        Text("Other").tag(Recipe.Kind.other)
                    }
                    if kind == .meal {
                        Picker("Servings", selection: $servings) {
                            ForEach(UInt(1)..<7, id: \.self) { count in
                                Text(count.description).tag(count)
                            }
                        }
                    } else {
                        TextField("Quantity", text: $quantity)
                    }
                }

                Section {
                    Picker("Book", selection: $book) {
                        ForEach(books) { book in
                            Text(book.shortName).tag(book)
                        }
                    }
                    if let book, book.hasPageNumbers {
                        TextField("Page number", value: $pageNumber, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                    }
                    TextField("URL", text: $url)
                }

                Section {
                    Toggle("Brand new recipe", isOn: $isBrandNew)
                }

                Section {
                    TextField("Notes", text: $notes)
                }
            }
            .navigationTitle("Add Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        createNewRecipe()
                        dismiss()
                    }
                    .bold()
                    .disabled(isInvalid)
                }
            }
        }
        .onAppear {
            onAppearFocus = true
            book = books.first
        }
    }

    private var isInvalid: Bool {
        guard let book else {
            return true
        }

        return name.isEmpty ||
               (book.hasPageNumbers && pageNumber == nil)
    }

    private func createNewRecipe() {
        Log.log("Create recipe '\(name)'")
        let recipe = Recipe(
            name: name,
            book: book!,
            pageNumber: pageNumber,
            url: url.emptyNil,
            kind: kind,
            servingsCount: servings,
            quantity: quantity.emptyNil,
            isImported: !isBrandNew,
            notes: notes
        )
        modelContext.insert(recipe)
        modelContext.trySave()
    }
}

#Preview(traits: .previewObjects) {
    CreateRecipeView()
}
