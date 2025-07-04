//
//  DefaultObjects.swift
//  Recipes
//
//  Created by John on 13/02/2025.
//

import SwiftUI
import SwiftData

struct PreviewObjects: PreviewModifier {
    static func makeSharedContext() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Schema(versionedSchema: CurrentSchema.self), configurations: config)
        DatabaseLoader.createObjects(modelContext: container.mainContext)
        return container
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content
            .modelContainer(context)
            .environment(UIState())
            .environment(Log.shared)
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    @MainActor static var previewObjects: Self = .modifier(PreviewObjects())
}
