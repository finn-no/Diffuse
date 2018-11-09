//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import Foundation

public struct Diffuse<T> where T: Equatable {
    public typealias ItemComparator = (T, T) -> Bool

    private init() {}

    public static func diff(old: [T], updated: [T]) -> CollectionChanges {
        return self.diff(old: old, updated: updated, comparator: {(itemA, itemB) in itemA == itemB})
    }

    public static func diff(old: [T], updated: [T], comparator: ItemComparator) -> CollectionChanges {
        let inserted = insertedItems(old: old, updated: updated, comparator: comparator)
        let removed = removedItems(old: old, updated: updated, comparator: comparator)
        let moved = movedItems(old: old, updated: updated, comparator: comparator)
        let updated = updatedItems(old: old, updated: updated, comparator: comparator)

        let allChanges = [inserted, removed, moved, updated].flatMap { $0 }

        return CollectionChanges(allChanges: allChanges)
    }

    private static func insertedItems(old oldItems: [T], updated updatedItems: [T], comparator: ItemComparator) -> [Change] {
        let updatedEnumerated = updatedItems.enumerated()

        // Find indices which are represented in `updatedItems`, but not in `oldItems`.
        let indices = {
            updatedEnumerated
                .map { updated in !oldItems.contains { comparator($0, updated.element) } ? updated.offset : nil }
                .flatMap { $0 }
        }()

        return indices.map { Change.insert(at: $0) }
    }

    private static func removedItems(old oldItems: [T], updated updatedItems: [T], comparator: ItemComparator) -> [Change] {
        let oldEnumerated = oldItems.enumerated()

        // Find indices which are represented in `oldItems`, but not in `updatedItems`.
        let indices = {
            oldEnumerated
                .map { old in !updatedItems.contains { comparator($0, old.element) } ? old.offset : nil }
                .flatMap { $0 }
        }()

        return indices.map { Change.remove(from: $0) }
    }

    private static func movedItems(old oldItems: [T], updated updatedItems: [T], comparator: ItemComparator) -> [Change] {
        let oldEnumerated = oldItems.enumerated()
        let updatedEnumerated = updatedItems.enumerated()

        // Find indices which exists in both `oldItems` and `updatedItems`, but have a different index.
        let indices = {
            updatedEnumerated.map { updated -> (from: Int, to: Int)? in
                oldEnumerated
                    .first { comparator($0.element, updated.element) && $0.offset != updated.offset }
                    .map { (from: $0.offset, to: updated.offset) }
                }.flatMap { $0 }
        }()
        return indices.map { Change.move(from: $0.from, to: $0.to) }
    }

    private static func updatedItems(old oldItems: [T], updated updatedItems: [T], comparator: ItemComparator) -> [Change] {
        let oldEnumerated = oldItems.enumerated()
        let updatedEnumerated = updatedItems.enumerated()

        // Find indices where `comparator` returns `true`, but the elements themselves don't match.
        let indices = {
            updatedEnumerated.map { updated -> Int? in
                oldEnumerated
                    .first { comparator($0.element, updated.element) && $0.element != updated.element }
                    .map { _ in updated.offset }
                }.flatMap { $0 }
        }()

        return indices.map { Change.updated(at: $0) }
    }
}
