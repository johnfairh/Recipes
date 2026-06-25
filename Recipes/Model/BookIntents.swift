//
//  Bookintents.swift
//  Recipes
//
//  Created by John on 25/06/2026.
//

import AppIntents
import SwiftData

// MARK: AppEntity - Book

struct BookEntity: IndexedEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation("Recipe")

    static var defaultQuery = BookEntityQuery()

    /// Book object unique ID: we use the name.
    ///
    /// This is a kludge - see RecipeEntity.
    let id: String

    @Property(title: "Book Name")
    var name: String

    @Property(title: "Book Details")
    var details: String

    let systemImageName: String?

    var displayRepresentation: DisplayRepresentation {
        let imageName = systemImageName ?? "book.fill"
        return DisplayRepresentation(title: "\(name)",
                                     subtitle: "\(details)",
                                     image: .init(systemName: imageName))
    }

    static func identifier(_ id: ID) -> EntityIdentifier {
        EntityIdentifier(for: Self.self, identifier: id)
    }

    init(_ book: Book) {
        self.id = book.shortName
        self.systemImageName = book.systemImageName
        self.name = book.shortName
        self.details = book.longName
    }
}

extension Book {
    var entityIdentifier: EntityIdentifier {
        BookEntity.identifier(shortName)
    }
}

// MARK: AppIntent - Book Queries

struct BookEntityQuery: EnumerableEntityQuery {
    @MainActor
    func entities(for identifiers: [BookEntity.ID]) async throws -> [BookEntity] {
        try Book.find(names: identifiers, modelContext: DatabaseLoader.intentsModelContext)
            .map(BookEntity.init)
    }

    @MainActor
    func suggestedEntities() async throws -> [BookEntity] {
        try await allEntities()
    }

    @MainActor
    func allEntities() async throws -> [BookEntity] {
        try Book.all(modelContext: DatabaseLoader.intentsModelContext)
            .map(BookEntity.init)
    }
}

// MARK: AppIntent - Book Delete Intent

enum BookIntentsError: Error, CustomLocalizedStringResourceConvertible {
    case bookNotEmpty

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .bookNotEmpty:
            return "Book still contains recipes"
        }
    }
}

struct BookDeleteIntent: AppIntent {
    static let title: LocalizedStringResource = "Delete Recipe Book"

    static let description = IntentDescription("Delete a recipe book.")

    @Parameter(title: "Book", description: "The recipe book to delete")
    var book: BookEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Delete \(\.$book)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let modelContext = DatabaseLoader.intentsModelContext
        let bookModel = try Book.find(entity: book, modelContext: modelContext)
        guard bookModel.recipes.isEmpty else {
            throw BookIntentsError.bookNotEmpty
        }
        bookModel.doDeleteAction(modelContext: modelContext, fromIntent: true)
        return .result()
    }
}

extension BookDeleteIntent {
    init(book: BookEntity) {
        self.book = book
    }
}
