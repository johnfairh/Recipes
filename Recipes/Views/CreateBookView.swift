//
//  CreateBookView.swift
//  Recipes
//
//  Created by John on 14/02/2025.
//

import SwiftUI
import SwiftData

struct CreateBookView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State var shortName: String = ""
    @State var longName: String = ""
    @State var symbolName: String = Book.defaultSymbolName
    @State var hasPageNumbers: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $shortName)
                    TextField("Description", text: $longName)
                }
                Section {
                    Picker("Icon", selection: $symbolName) {
                        Image(systemName: "brain.head.profile").tag("brain.head.profile")
                        Image(systemName: "book.closed").tag("book.closed")
                    }
                }
                Section {
                    Toggle("Has page numbers", isOn: $hasPageNumbers)
                }
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        createNewBook()
                        dismiss()
                    }
                    .bold()
                    .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        !shortName.isEmpty
    }

    private func createNewBook() {
        Log.log("Create book '\(shortName)'")
        let book = Book(shortName: shortName, longName: longName, symbolName: symbolName, hasPageNumbers: hasPageNumbers, sortOrder: Book.nextSortOrder(modelContext: modelContext))
        modelContext.insert(book)
        modelContext.trySave()
    }
}

#Preview(traits: .previewObjects) {
    CreateBookView()
}
