//
//  LogView.swift
//  Recipes
//
//  Created by John on 12/02/2025.
//
import SwiftUI

struct LogView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
            Text("Log")

            Button {
                dismiss()
            } label: {
                Text("OK")
            }
    }
}
