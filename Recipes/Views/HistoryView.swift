//
//  CookingsView.swift
//  Recipes
//
//  Created by John on 30/06/2025.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(UIState.self) var uiState: UIState

    var body: some View {
        @Bindable var uiState = uiState.historyTab
        NavigationStack {
            List {
                HistoryListView(searchText: uiState.searchText)
            }
            .navigationTitle("History")
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .searchable(text: $uiState.searchText, placement: .automatic/*navigationBarDrawer*/, prompt: "Recipe name")
        }
    }
}

struct HistoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(UIState.self) var appUIState: UIState

    private let searchText: String

    @SectionedQuery(\Cooking.monthCode, sort: \Cooking.timestamp, order: .reverse)
    private var cookings: SectionedResults<Int, Cooking>

    init(searchText: String) {
        self.searchText = searchText
        let predicate = #Predicate<Cooking> { cooking in
            searchText.isEmpty ||
            cooking.recipe.name.localizedStandardContains(searchText)
        }
        _cookings = SectionedQuery(\.monthCode, filter: predicate, sort: \.timestamp, order: .reverse)
    }

    var body: some View {
        if !searchText.isEmpty && cookings.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            ForEach(cookings) { section in
                Section(section.id.decodeMonthCode) {
                    ForEach(section) { cooking in
                        HStack {
                            Image(systemName: cooking.recipe.symbolName)
                                .imageScale(.large)
                                .foregroundStyle(Color.accentColor)
                                .frame(minWidth: 32, maxWidth: 32)
                            VStack(alignment: .leading) {
                                Text(cooking.recipe.name).font(.title3)
                                Text(cooking.timestamp.formatted(date: .complete, time: .omitted)).font(.body)
                            }
                            .padding(.leading, 8)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            appUIState.show(recipe: cooking.recipe)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                cooking.doDeleteAction(modelContext: modelContext)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview(traits: .previewObjects) {
    HistoryView()
}
