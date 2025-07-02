//
//  CookingsView.swift
//  Recipes
//
//  Created by John on 30/06/2025.
//

// UIState refactor per-tab
// Move filtering & sheet popup from recipes into uistate
// Do Books
// Methods on UIState?

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(UIState.self) var uiState: UIState

    @SectionedQuery(\Cooking.monthCode, sort: \Cooking.timestamp, order: .reverse)
    var cookings: SectionedResults<Int, Cooking>

    var searchedCookings: SectionedResults<Int, Cooking> {
        if uiState.historySearchText.isEmpty {
            return cookings
        }
        return cookings.filter { $0.recipe.name.localizedCaseInsensitiveContains(uiState.historySearchText) }
    }

    var body: some View {
        @Bindable var uiState = uiState
        NavigationStack {
            List {
                if !uiState.historySearchText.isEmpty && searchedCookings.isEmpty {
                    ContentUnavailableView.search(text: uiState.historySearchText)
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
                                    uiState.selectedRecipe = cooking.recipe
                                    uiState.selectedTab = .recipes
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
            .searchable(text: $uiState.historySearchText, placement: .navigationBarDrawer, prompt: "Recipe name")
        }
    }
}

#Preview(traits: .previewObjects) {
    HistoryView()
}
