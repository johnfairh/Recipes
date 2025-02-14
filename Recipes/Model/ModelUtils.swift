//
//  ModelUtils.swift
//  Recipes
//
//  Created by John on 13/02/2025.
//

protocol WithSortOrder {
    var sortOrder: UInt { get }
}

extension WithSortOrder {
    static func nextSortOrder(all: [Self]) -> UInt {
        all.reduce(0) { soFar, next in
            return max(soFar, next.sortOrder)
        } + 1
    }
}
