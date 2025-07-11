//
//  Tag.swift
//  Recipes
//
//  Created by John on 10/07/2025.
//

import SwiftData
import Foundation

/// New in V4
extension CurrentSchema {
    @Model
    class Tag {
        @Attribute(.unique)
        var name: String

        var colorRGB: UInt32

        var recipes: [Recipe] = []

        init(name: String) {
            self.name = name
            self.colorRGB = 0
            self.recipes = []
        }
    }
}
