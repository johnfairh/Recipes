//
//  RecipeFilterView.swift
//  Recipes
//
//  Created by John on 24/06/2025.
//

import SwiftUI
import SwiftData

struct RecipeFilterItemView: View {
    @Binding var filter: RecipeFilter
    let books: [Book]

    @State var string = "boo"

    var body: some View {
        switch filter.kind {
        case .name, .url, .quantity, .notes:
            RegexTextField(regex: $filter.regex, regexView: $filter.regexView, prompt: "Regex")

        case .neverCooked, .importedCooked:
            EmptyView()

        case .book:
            Picker("Book", selection: $filter.book) {
                ForEach(books) { book in
                    Text(book.shortName).tag(book)
                }
            }
            .onAppear {
                if filter.book == nil, let firstBook = books.first {
                    filter.book = firstBook
                }
            }

        case .kind:
            Picker("Type", selection: $filter.recipeKind) {
                Text("Meal").tag(Recipe.Kind.meal)
                Text("Sweet").tag(Recipe.Kind.sweet)
                Text("Other").tag(Recipe.Kind.other)
            }

        case .cookedSince:
            DatePicker("", selection: $filter.date, displayedComponents: [.date])
                .datePickerStyle(.automatic)
                .offset(y: -24)

        case .servings:
            Menu {
                Button("=") {
                    filter.exact = true
                }
                Button(">=") {
                    filter.exact = false
                }
            } label: {
                Text(filter.exact ? "=" : ">=")
            }
            Stepper(String(filter.count), value: $filter.count, in: 1...10)
                .offset(y: -24)
        }
    }
}

struct RecipeFilterView: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Book.sortOrder) private var books: [Book]

    // Current filters being used in the parent listview
    @Binding var savedFilterList: RecipeFilterList?
    // Filters we are modelling in this view's UI
    @State var filterList: RecipeFilterList = .sample

    init(filterList: Binding<RecipeFilterList?>) {
        self._savedFilterList = filterList
    }

    var body: some View {
        VStack {
            HStack {
                Button("", systemImage: "xmark.circle", role: .destructive) {
                    filterList = .empty
                }
                Spacer()
                Text("Set Filters")
                    .font(.title)
                    .bold()
                Spacer()
                Button("", systemImage: "checkmark.circle") {
                    apply()
                }
            }
            .font(.title)
            .padding(.top, 6)

            HStack {
                Menu {
                    Button("Match all") {
                        filterList.allNotAny = true
                    }
                    Button("Match any") {
                        filterList.allNotAny = false
                    }
                } label: {
                    Text(filterList.allNotAny ? "Match all:" : "Match any:")
                }
                Spacer()
            }
            .padding(.bottom, 4)

            ForEach($filterList.filters) { $filter in
                HStack(alignment: .firstTextBaseline) {
                    Menu {
                        Button("Include", systemImage: "text.badge.plus") {
                            filter.includeNotExclude = true
                        }
                        Button("Exclude", systemImage: "text.badge.minus") {
                            filter.includeNotExclude = false
                        }
                    } label: {
                        Image(systemName: filter.includeNotExclude ? "text.badge.plus" : "text.badge.minus")
                    }

                    Text(filter.kind.label)
                    RecipeFilterItemView(filter: $filter, books: books)

                    Spacer()
                    Button(role: .destructive) {
                        let idx = filterList.filters.firstIndex(where: { $0.id == filter.id})!
                        filterList.filters.remove(at: idx)
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                }
            }

            HStack {
                Spacer()
                Menu {
                    ForEach(RecipeFilter.Kind.allCases) { kind in
                        Button(kind.label) {
                            filterList.filters.append(RecipeFilter(kind: kind))
                        }
                    }
                } label: {
                    Image(systemName: "plus.circle")
                }
            }.padding(.top, 4)

            Spacer()
        }
        .padding()
        .onAppear() {
            if let currentFilters = savedFilterList {
                filterList = currentFilters
            }
        }
    }

    func apply() {
        if filterList.filters.isEmpty {
            savedFilterList = nil
        } else {
            savedFilterList = filterList
        }
        dismiss()
    }
}

private struct RecipeFilterPreviewView: View {
    @State var filterList: RecipeFilterList?
    var body: some View {
        RecipeFilterView(filterList: $filterList)
    }
}

#Preview(traits: .previewObjects, .sizeThatFitsLayout) {
    RecipeFilterPreviewView()
}
