//
//  AIView.swift
//  Recipes
//
//  Created by John on 10/03/2026.
//

import SwiftUI
import SwiftData

struct AIView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(UIState.self) var appUIState: UIState

    var uiState: UIState.AITab {
        appUIState.aiTab
    }

    var body: some View {
        @Bindable var uiState = uiState
        NavigationStack {
            if let unavailableReason = RecipesAgent.unavailability {
                ContentUnavailableView {
                    Label("Not Available", systemImage: "apple.intelligence")
                } description: {
                    Text(unavailableReason)
                }
            } else {
                VStack {
                    Text(uiState.responseText)
                        .padding()
                    Spacer()
                    HStack {
                        TextField("Ask something", text: $uiState.questionText)
                        if !uiState.responding {
                            Button("", systemImage: "arrow.up.circle") {
                                uiState.responding = true
                                Task {
                                    do {
                                        uiState.responseText = try await RecipesAgent.request(uiState.questionText)
                                    } catch {
                                        // XXX decode this error better
                                        uiState.responseText = "Error: \(error)"
                                    }
                                    uiState.responding = false
                                }
                            }
                        }
                    }
                }.padding()
            }
        }
    }
}

#Preview(traits: .previewObjects) {
    AIView()
}
