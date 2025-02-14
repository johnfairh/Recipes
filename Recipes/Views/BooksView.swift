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
    @Query(sort: \Book.sortOrder) private var books: [Book]

    @State private var isCheckingReset: Bool = false
    @State private var isShowingLog: Bool = false

    @State private var isShowingCreate: Bool = false

    var body: some View {
        NavigationSplitView {
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
                        Text("\(book.recipes.count.description) \(book.sortOrder)")

                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Books")
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
                DevMenu

                ToolbarItem {
                    Button("Add Book", systemImage: "plus") {
                        isShowingCreate = true
                    }
                }
            }
        } detail: {
            Text("Select an item")
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
        .sheet(isPresented: $isShowingLog) {
            LogView()
        }
        .sheet(isPresented: $isShowingCreate) {
            CreateBookView()
        }
    }

    @ToolbarContentBuilder
    private var DevMenu: some ToolbarContent {
        ToolbarItem {
            Menu {
                Button("Log", systemImage: "pencil.and.list.clipboard") {
                    isShowingLog = true
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
//            for index in offsets {
//                modelContext.delete(items[index])
//            }
        }
    }
}

#Preview(traits: .previewObjects) {
    BooksView()
}
