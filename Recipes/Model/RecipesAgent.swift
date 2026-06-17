//
//  RecipesAgent.swift
//  Recipes
//
//  Created by John on 10/03/2026.
//


// So.  This is all hooked up fine, I think.
//
// The first problem is that the thing won't talk to me - gives "empty thought" errors
// that are not documented in a way I can find - will need the internet back.  It may
// be trying to tell me that the internet is not working.
//
// The second problem is more of a worry - that this is not a suitable application
// because the context window is only 4000 tokens.  I have say 200 recipes, and 20 tokens
// per is not a large budget.  Seems to preclude adding things like tags and going deeper
// into stats and so on about the history.
//
// There might be an approach that just has the model create a query from some human
// request - this is just what the filter screen does really. Not a lot of space for the
// model to add value - I was hoping it might have some world knowledge helpful for
// responding to vaguer queries but I suppose that is just a toy again (I wouldn't use
// it!)
//
// I think power through the teething problem here, see if it can be made to work at all.
// But this is probably just a learning / timewasting exercise rather than a decent thing;
// tags or visualization would be better.

import FoundationModels

struct RecipesAgent {
    /// Return `nil` if AI is ready to go, otherwise a reason why not
    static var unavailability: String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Apple Intelligence Is Not Enabled"
        case .unavailable(.deviceNotEligible):
            return "Apple Intelligence Is Too Powerful"
        case .unavailable(.modelNotReady):
            return "Apple Intelligence Is Unready"
        case .unavailable(let reason):
            return "Apple Intelligence is Confused: \(reason)"
        }
    }

    private static let instructions = "You are a recipes planning and cooking history assistant. Your role is to suggest recipes and answer questions about the cooking history."

    static func request(_ text: String) async throws -> String {
        let session = LanguageModelSession(tools: [ListRecipesTool()], instructions: instructions)
        return try await session.respond(to: text).content
    }
}

@Generable
struct GenerableRecipe {
    let name: String
    let servings: String
    let isCookedBefore: Bool

    init(_ recipe: Recipe) {
        self.name = recipe.name
        self.servings = recipe.servings
        self.isCookedBefore = recipe.lastCookedTime != nil
    }
}

// tool - search recipes (string) (tag)// tool - list recipes ?
// tool - list cooking history (since date) ?

struct ListRecipesTool: Tool {
    let name = "listRecipes"
    let description = "List known recipes"

    @Generable
    struct Arguments {
        @Guide(description: "Include recipes that have not been cooked")
        let includeUncooked: Bool
    }

    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        try await MainActor.run {
            let modelContext = DatabaseLoader.modelContainer.mainContext
            let allGenerable = try Recipe.all(modelContext: modelContext).map(GenerableRecipe.init)
            return allGenerable.filter { arguments.includeUncooked || $0.isCookedBefore }
        }
    }
}
