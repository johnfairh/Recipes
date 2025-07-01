//
//  CookingsView.swift
//  Recipes
//
//  Created by John on 30/06/2025.
//

// NavigationState adventure - to add history from recipe-view and recipe-view from history cell-click

import SwiftUI
import SwiftData

struct HistoryView: View {
    @SectionedQuery(\Cooking.monthCode, sort: \Cooking.timestamp, order: .reverse)
    var cookings: SectionedResults<Int, Cooking>

    @State var searchText = ""

    var searchedCookings: SectionedResults<Int, Cooking> {
        if searchText.isEmpty {
            return cookings
        }
        return cookings.filter { $0.recipe.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                if !searchText.isEmpty && searchedCookings.isEmpty {
                    ContentUnavailableView.search(text: searchText)
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
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "Recipe name")
        }
    }
}

#Preview(traits: .previewObjects) {
    HistoryView()
}
