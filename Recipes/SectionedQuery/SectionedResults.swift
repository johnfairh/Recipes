//
//  SectionedResults.swift
//  
//  Created by Thomas Magis-Agosta on 9/27/23.
//  Heavily modified by JF.
//

import SwiftData
import SwiftUI

/// A collection of models retrieved from a SwiftData persistent store, grouped into sections.
public struct SectionedResults<SectionIdentifier, Result>: Equatable, RandomAccessCollection
where SectionIdentifier: Hashable, Result: PersistentModel {
    /// A type that represents an element in the collection.
    public typealias Element     = SectionedResults<SectionIdentifier, Result>.Section
    /// A type that represents a position in the collection.
    public typealias Index       = Int
    /// A type that represents the indices that are valid for subscripting the collection, in ascending order.
    public typealias Indices     = Range<Int>
    /// A type that provides the collection’s iteration interface and encapsulates its iteration state.
    public typealias Iterator    = IndexingIterator<SectionedResults<SectionIdentifier, Result>>
    /// A collection representing a contiguous subrange of this collection’s elements. The subsequence shares indices with the original collection.
    public typealias SubSequence = Slice<SectionedResults<SectionIdentifier, Result>>

    /// The key path that the system uses to group results into sections.
    public let sectionIdentifier: KeyPath<Result, SectionIdentifier>
    /// The collection of results that share a specified identifier.
    public let sections: [Section]
    /// The index of the first section in the results collection.
    public var startIndex: Int { 0 }
    /// The index that’s one greater than that of the last section.
    public var endIndex: Int { sections.count }

    /// Gets the section at the specified index.
    public subscript(position: Int) -> Section {
        get { sections[position] }
    }

    /// Conform to equatable
    /// (JF: dunno what this is really for, perhaps SwiftUI stuff, ignores the keypath... also original version didn't  actually compare the elements??)
    public static func == (lhs: SectionedResults<SectionIdentifier, Result>, rhs: SectionedResults<SectionIdentifier, Result>) -> Bool {
        guard lhs.sections.count == rhs.sections.count else {
            return false
        }
        if lhs.sections.count == 0 && rhs.sections.count == 0 {
            return true
        }

        for range in 0...lhs.sections.count-1 {
            if lhs.sections[range].elements != rhs.sections[range].elements {
                return false
            }
        }
        return true
    }

    init(sectionIdentifier: KeyPath<Result, SectionIdentifier>, results: [Result]) {
        self.sectionIdentifier = sectionIdentifier

        var sections: [Section] = []

        var currentResults: [Result] = []
        var currentID: SectionIdentifier? = nil

        for result in results {
            let id = result[keyPath: sectionIdentifier]
            if currentID == nil {
                currentID = id
            } else if id != currentID! {
                sections.append(Section(id: currentID!, elements: currentResults))
                currentResults = []
                currentID = id
            }
            currentResults.append(result)
        }
        if let currentID {
            sections.append(Section(id: currentID, elements: currentResults))
        }
        self.sections = sections
    }

    private init(sectionIdentifier: KeyPath<Result, SectionIdentifier>, sections: [Section]) {
        self.sectionIdentifier = sectionIdentifier
        self.sections = sections
    }

    public func filter(_ isIncluded: (Result) throws -> Bool) rethrows -> Self {
        let newSections = try sections.compactMap { section -> Section? in
            let newResults = try section.elements.filter(isIncluded)
            if newResults.isEmpty { return nil }
            return Section(id: section.id, elements: newResults)
        }
        return .init(sectionIdentifier: sectionIdentifier, sections: newSections)
    }

    /// The collection of models that share a specified identifier.
    public struct Section: RandomAccessCollection, Identifiable {
        /// A type that represents an element in the collection.
        public typealias Element     = Result
        /// A type that represents the ID of the collection.
        public typealias ID          = SectionIdentifier
        /// A type that represents a position in the collection.
        public typealias Index       = Int
        /// A type that represents the indices that are valid for subscripting the collection, in ascending order.
        public typealias Indices     = Range<Int>
        /// A type that provides the collection’s iteration interface and encapsulates its iteration state.
        public typealias Iterator    = IndexingIterator<SectionedResults<SectionIdentifier, Result>.Section>
        /// A collection representing a contiguous subrange of this collection’s elements. The subsequence shares indices with the original collection.
        public typealias SubSequence = Slice<SectionedResults<SectionIdentifier, Result>.Section>

        /// The section identifier.
        public let id: ID
        /// The collection of results for the section.
        public let elements: [Element]
        /// The index of the first element in the results collection.
        public var startIndex: Int { 0 }
        /// The index that’s one greater than that of the last element.
        public var endIndex: Int { elements.count }

        /// Gets the element at the specified index.
        public subscript(position: Int) -> Result {
            get { elements[position] }
        }

        init(id: ID, elements: [Element]) {
            self.id       = id
            self.elements = elements
        }
    }
}
