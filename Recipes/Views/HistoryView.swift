//
//  CookingsView.swift
//  Recipes
//
//  Created by John on 30/06/2025.
//

// Searchable - try overlay NotFound & backport
// NavigationState adventure - to add history from recipe-view and recipe-view from history cell-click

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Cooking.timestamp, order: .reverse) var cookings2: [Cooking]

    @SectionedQuery(\Cooking.monthCode, sort: \Cooking.timestamp, order: .reverse)
    var cookings: SectionedResults<Int, Cooking>

    var body: some View {
        NavigationStack {
            List {
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
                        }
                    }
                }
            }
            .navigationTitle("History")
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
        }
    }
}

#Preview(traits: .previewObjects) {
    HistoryView()
}
