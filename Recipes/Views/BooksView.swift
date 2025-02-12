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
    @Query private var items: [Item]

    @State private var isCheckingReset: Bool = false
    @State private var isShowingLog: Bool = false

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
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
                    Button("Add Item", systemImage: "plus", action: addItem)
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
                Button("Reset", systemImage: "exclamationmark.square", role: .destructive) {
                    isCheckingReset = true
                }
            } label: {
                Label("Dev", systemImage: "gear")
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    BooksView()
        .modelContainer(for: Item.self, inMemory: true)
}

