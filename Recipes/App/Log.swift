//
//  Log.swift
//  Recipes
//
//  Created by John on 11/02/2025.
//
import Observation
import Foundation

@Observable
class Log {
    struct Line: Identifiable {
        let id: UUID
        let date: Date
        let line: String
    }

    private(set) var lines: [Line]

    init() {
        lines = []
    }

    func log(_ line: String) {
        print("LOG: \(line)")
        lines.append(Line(id: UUID(), date: Date.now, line: line))
    }

    static let shared = Log()
    static func log(_ s: String) {
        shared.log(s)
    }
}
