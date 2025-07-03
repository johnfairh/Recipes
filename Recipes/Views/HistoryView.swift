//
//  CookingsView.swift
//  Recipes
//
//  Created by John on 30/06/2025.
//

// Add filtering + create into UIState
// Do Books

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(UIState.self) var appUIState: UIState

    var uiState: UIState.HistoryTab {
        appUIState.historyTab
    }

    @SectionedQuery(\Cooking.monthCode, sort: \Cooking.timestamp, order: .reverse)
    var cookings: SectionedResults<Int, Cooking>

    var searchedCookings: SectionedResults<Int, Cooking> {
        if uiState.searchText.isEmpty {
            return cookings
        }
        return cookings.filter { $0.recipe.name.localizedCaseInsensitiveContains(uiState.searchText) }
    }

    var body: some View {
        @Bindable var uiState = uiState
        NavigationStack {
            List {
                if !uiState.searchText.isEmpty && searchedCookings.isEmpty {
                    ContentUnavailableView.search(text: uiState.searchText)
                } else {
                    ForEach(searchedCookings) { section in
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
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .searchable(text: $uiState.searchText, placement: .navigationBarDrawer, prompt: "Recipe name")
        }
    }
}

#Preview(traits: .previewObjects) {
    HistoryView()
}
