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
        var changes = [Change]()

        // Find indices which are represented in `updatedItems`, but not in `oldItems`.
        for updated in updatedEnumerated {
            guard !oldItems.contains(where: { comparator($0, updated.element) }) else { continue }
            changes.append(Change.insert(at: updated.offset))
        }

        return changes
    }

    private static func removedItems(old oldItems: [T], updated updatedItems: [T], comparator: ItemComparator) -> [Change] {
        let oldEnumerated = oldItems.enumerated()
        var changes = [Change]()

        // Find indices which are represented in `oldItems`, but not in `updatedItems`.
        for old in oldEnumerated {
            guard !updatedItems.contains(where: { comparator($0, old.element) }) else { continue }
            changes.append(Change.remove(from: old.offset))
        }

        return changes
    }

    private static func movedItems(old oldItems: [T], updated updatedItems: [T], comparator: ItemComparator) -> [Change] {
        let oldEnumerated = oldItems.enumerated()
        let updatedEnumerated = updatedItems.enumerated()
        var changes = [Change]()

        // Find indices which exists in both `oldItems` and `updatedItems`, but have a different index.
        for updated in updatedEnumerated {
            for old in oldEnumerated {
                guard comparator(old.element, updated.element), old.offset != updated.offset else { continue }
                changes.append(Change.move(from: old.offset, to: updated.offset))
                break
            }
        }

        return changes
    }

    private static func updatedItems(old oldItems: [T], updated updatedItems: [T], comparator: ItemComparator) -> [Change] {
        let oldEnumerated = oldItems.enumerated()
        let updatedEnumerated = updatedItems.enumerated()
        var changes = [Change]()

        // Find indices where `comparator` returns `true`, but the elements themselves don't match.
        for updated in updatedEnumerated {
            for old in oldEnumerated {
                guard comparator(old.element, updated.element), old.element != updated.element else { continue }
                changes.append(Change.updated(at: updated.offset))
                break
            }
        }

        return changes
    }
}
