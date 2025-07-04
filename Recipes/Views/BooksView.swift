//
//  BooksView.swift
//  Recipes
//
//  Created by John on 12/02/2025.
//

import SwiftUI
import SwiftData

struct BooksView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(UIState.self) var appUIState: UIState

    var uiState: UIState.BooksTab {
        appUIState.booksTab
    }

    @Query(sort: \Book.sortOrder) private var books: [Book]

    @State private var isCheckingReset: Bool = false

    var body: some View {
        @Bindable var uiState = uiState
        NavigationStack {//plitView {
            List {
                ForEach(books) { book in
                    HStack {
                        Image(systemName: book.symbolName)
                            .imageScale(.large)
                            .foregroundStyle(Color.accentColor)
                            .frame(minWidth: 32, maxWidth: 32)
                        VStack(alignment: .leading) {
                            Text(book.shortName).font(.title3)
                            Text(book.longName).font(.body)
                        }
                        .padding(.leading, 8)
                        Spacer()
                        Text(book.recipes.count.description)
                    }
                    .deleteDisabled(book.recipes.count > 0)
                    .contentShape(Rectangle()) // this makes the hittest cover the entire cell...
                    .onTapGesture {
                        if uiState.selected == book {
                            uiState.selected = nil
                        } else {
                            uiState.selected = book
                        }
                    }
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItems)
            }
            .navigationTitle("Books")
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
                DevMenu

                ToolbarItem {
                    Button("Add Book", systemImage: "plus") {
                        uiState.sheet = .create
                    }
                }
            }
//        } detail: {
//            Text("Select an item")
        }
        .confirmationDialog(
            "Are you sure?",
            isPresented: $isCheckingReset
        ) {
            Button("Reset all data and quit Recipes?", role: .destructive) {
                DatabaseLoader.importExport.reset()
                try? modelContext.save()
                exit(0) // I guess
            }
        }
        .sheet(isPresented: .asBool($uiState.sheet)) {
            switch uiState.sheet {
            case .none:
                EmptyView()
            case .create:
                CreateEditBookView(parentModelContext: modelContext)
            case .log:
                LogView()
            }
        }
        .sheet(item: $uiState.selected) { itm in
            CreateEditBookView(parentModelContext: modelContext, book: itm)
        }
    }

    @ToolbarContentBuilder
    private var DevMenu: some ToolbarContent {
        ToolbarItem {
            Menu {
                Button("Log", systemImage: "pencil.and.list.clipboard") {
                    uiState.sheet = .log
                }
                Button("Export", systemImage: "square.and.arrow.up.on.square") {
                    DatabaseLoader.importExport.export()
                }
                Button("Defaults", systemImage: "book.and.wrench.fill") {
                    DatabaseLoader.createObjects(modelContext: modelContext)
                }
                Button("Reset", systemImage: "exclamationmark.square", role: .destructive) {
                    isCheckingReset = true
                }
            } label: {
                Label("Dev", systemImage: "gear")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let book = books[index]
                Log.log("Delete book \(book.shortName)")
                modelContext.delete(book)
            }
        }
        modelContext.trySave()
    }

    // Yikes: rewrite the sort order for all the objects.
    // Apparently this is how TMLPresentation works as well - I was sure there
    // was some clever 'exchange order' thing but no, is not possible (floating point?)
    // and, well, this seems OK.  Especially here when #books is small.
    private func moveItems(from source: IndexSet, to destination: Int) {
        var items = books
        items.move(fromOffsets: source, toOffset: destination)
        let indices = items.map(\.sortOrder).sorted()
        zip(items, indices).forEach { $0.sortOrder = $1 }
        modelContext.trySave()
    }
}

#Preview(traits: .previewObjects) {
    BooksView()
}
