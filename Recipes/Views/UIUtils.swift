//
//  UIUtils.swift
//  Recipes
//
//  Created by John on 28/05/2025.
//

import SwiftUI

extension Binding {
    /// Manage a `String?` model property with a `String` in the UI - write `nil` for an empty string
    static func emptyNilString(_ backing: Binding<String?>) -> Binding<String> {
        Binding<String>(get: { backing.wrappedValue ?? "" }, set: { backing.wrappedValue = $0.emptyNil })
    }

    /// Manage a `Bool` model property - invert the UI boolean
    static func invertBool(_ backing: Binding<Bool>) -> Binding<Bool> {
        Binding<Bool>(get: { !backing.wrappedValue }, set: { backing.wrappedValue = !$0 })
    }
}

extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct RegexTextField: View {
    init(regex: Binding<any RegexComponent>, regexView: Binding<String>, prompt: String) {
        self.regex = regex
        self.regexView = regexView
        self.prompt = prompt
    }

    var regex: Binding<any RegexComponent>
    var regexView: Binding<String>
    let prompt: String
    @State var valid: Bool = true

    var body: some View {
        VStack(alignment: .leading) {
            TextField("", text: regexView, prompt: Text(prompt))
                .onChange(of: regexView.wrappedValue) { _, newValue in
                    if let re = try? Regex(newValue).ignoresCase() {
                        valid = true
                        regex.wrappedValue = re
                    } else {
                        valid = false
                    }
                }
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
            if !valid {
                Text("Invalid regex")
                    .font(.footnote)
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: MultiLineTextField

/// This adds a prompt & a minimum height to a ``TextEditor``.`
struct MultiLineTextField: View {
    init(text: Binding<String>, prompt: String, minHeight: CGFloat = 180) {
        self.text = text
        self.prompt = prompt
        self.minHeight = minHeight
    }

    var text: Binding<String>
    let prompt: String
    let minHeight: CGFloat

    var body: some View {
        TextEditor(text: text)
            .frame(minHeight: minHeight)
            .overlay {
                if text.wrappedValue.isEmpty {
                    VStack {
                        HStack {
                            Text(prompt)
                                .foregroundStyle(Color.secondary)
                                .padding(4)
                                .padding(.top, 4)
                            Spacer()
                        }
                        Spacer()
                    }
                    .allowsHitTesting(false)
                }
            }
    }
}
