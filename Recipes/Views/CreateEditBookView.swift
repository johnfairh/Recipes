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
        isCreate ? "New Book" : "Edit Book"
    }

    init(parentModelContext: ModelContext, book: Book? = nil) {
        modelContext = ModelContext(parentModelContext.container)
        modelContext.autosaveEnabled = false
        if let book {
            self.book = modelContext.model(for: book.id) as! Book
            isCreate = false
        } else {
            self.book = Book(shortName: "", longName: "", symbolName: Book.defaultSymbolName, hasPageNumbers: false,
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
                        ForEach(Book.symbolNames, id: \.self) { symbolName in
                            Image(systemName: symbolName).tag(symbolName)
                        }
                    }
                }
                Section("Details") {
                    Toggle("Has page numbers", isOn: $book.hasPageNumbers)
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
                        saveBook()
                        dismiss()
                    }
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


struct CreateBookWrapperView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        CreateEditBookView(parentModelContext: modelContext)
    }
}

#Preview(traits: .previewObjects) {
    CreateBookWrapperView()
}
