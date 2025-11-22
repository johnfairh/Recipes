//
//  LogView.swift
//  Recipes
//
//  Created by John on 12/02/2025.
//
import SwiftUI

struct LogView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            LogContentView()
                .navigationTitle("Log")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    Button(role: .close) {
                        dismiss()
                    }
                }
                .padding()
        }
    }
}

struct LogContentView: View {
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
    }
}

#Preview(traits: .previewObjects) {
    LogView()
}
