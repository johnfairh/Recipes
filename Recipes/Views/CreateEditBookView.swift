//
//  CreateEditBookView.swift
//  Recipes
//
//  Created by John on 28/05/2025.
//

import SwiftUI
import SwiftData

struct CreateEditBookView: View {
    @Environment(\.dismiss) private var dismiss

    @FocusState private var onAppearFocus: Bool

    private var modelContext: ModelContext

    @Bindable var book: Book

    let isCreate: Bool
    var sheetTitle: String {
        isCreate ? "Add Book" : "Edit Book"
    }

    init(parentModelContext: ModelContext, book: Book? = nil) {
        modelContext = ModelContext(parentModelContext.container)
        modelContext.autosaveEnabled = false
        if let book {
            self.book = modelContext.model(for: book.id) as! Book
            isCreate = false
        } else {
            self.book = Book(shortName: "", longName: "", symbolName: "", hasPageNumbers: false,
                             sortOrder: Book.nextSortOrder(modelContext: modelContext))
            isCreate = true
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Name", text: $book.shortName)
                        .focused($onAppearFocus)
                    TextField("Description", text: $book.longName)
                }
                Section("Icon") {
                    Picker("Icon", selection: $book.symbolName) {
                        Image(systemName: "brain.head.profile").tag("brain.head.profile")
                        Image(systemName: "book.closed").tag("book.closed")
                    }
                }
                Section("Details") {
                    Toggle("Has page numbers", isOn: $book.hasPageNumbers)
                }
            }
            .navigationTitle(sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveBook()
                        dismiss()
                    }
                    .bold()
                    .disabled(!canSave)
                }
            }
        }
        .onAppear {
            onAppearFocus = true
        }
    }

    private var canSave: Bool {
        !book.shortName.isEmpty
    }

    private func saveBook() {
        if isCreate {
            Log.log("Create book '\(book.shortName)'")
            modelContext.insert(book)
        } else {
            Log.log("Commit changes to book '\(book.shortName)'")
        }

        modelContext.trySave()
    }
}
