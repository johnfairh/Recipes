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

///
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
