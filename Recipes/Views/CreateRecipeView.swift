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

    @State var name: String = ""
    @State var book: Book?
    @State var pageNumber: UInt? = nil
    @State var url: String = ""
    @State var isMeal: Bool = true
    @State var servings: UInt = 1
    @State var quantity: String = ""
    @State var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                }

                Section {
                    Picker("Type", selection: $isMeal) {
                        Text("Meal").tag(true)
                        Text("Sweet").tag(false)
                    }
                    if isMeal {
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
                        TextField("URL", text: $url)
                    }
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
            book = books.first
        }
    }

    private var isInvalid: Bool {
        name.isEmpty ||
        book == nil ||
        (book != nil && pageNumber == nil)

    }

    private func createNewRecipe() {
        let recipe = Recipe(
            name: name,
            book: book!,
            pageNumber: pageNumber,
            url: url.emptyNil,
            isMeal: isMeal,
            servingsCount: servings,
            quantity: quantity.emptyNil,
            notes: notes
        )
        modelContext.insert(recipe)
        modelContext.trySave()
    }
}

#Preview(traits: .previewObjects) {
    CreateRecipeView()
}
