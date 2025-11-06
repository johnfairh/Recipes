//
//  LogView.swift
//  Recipes
//
//  Created by John on 12/02/2025.
//
import SwiftUI

struct LogView: View {
    var body: some View {
        NavigationStack {
            LogContentView()
                .navigationTitle("Log")
                .navigationBarTitleDisplayMode(.inline)
                .padding()
        }
    }
}

struct LogContentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Log.self) private var log

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(log.lines) { line in
                    Text(try! AttributedString(markdown: "_\(line.timestamp)_ \(line.line)"))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }

        Button("OK") {
            dismiss()
        }
    }
}
