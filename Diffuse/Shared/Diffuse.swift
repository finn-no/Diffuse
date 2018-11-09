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
        let oldEnumerated = old.enumerated()
        let updatedEnumerated = updated.enumerated()

        var insertedItems = [Change]()
        var removedItems = [Change]()
        var updatedItems = [Change]()
        var movedItems = [Change]()

        // DELETED - Find indices which are represented in `oldItems`, but not in `updatedItems`.
        for old in oldEnumerated {
            guard !updatedEnumerated.contains(where: { comparator($0.element, old.element) }) else { continue }
            removedItems.append(Change.remove(from: old.offset))
        }

        for updated in updatedEnumerated {
            var foundMoved = false
            var foundUpdated = false

            // INSERTED - Find indices which are represented in `updatedItems`, but not in `oldItems`.
            if !oldEnumerated.contains(where: { comparator($0.element, updated.element) }) {
                insertedItems.append(Change.insert(at: updated.offset))

                // If an item is inserted, it will definitely not be either modified or updated. Skip to next iteration.
                continue
            }

            for old in oldEnumerated {
                // Stop iterating `oldEnumerated` if we know the element is both updated and moved.
                if foundUpdated && foundMoved { break }

                if comparator(old.element, updated.element) {
                    // MOVED - Find indices which exists in both `oldItems` and `updatedItems`, but have a different index.
                    if !foundMoved && old.offset != updated.offset {
                        movedItems.append(.move(from: old.offset, to: updated.offset))
                        foundMoved = true
                    }

                    // UPDATED - Find indices where `comparator` returns `true`, but the elements themselves don't match.
                    if !foundUpdated && old.element != updated.element {
                        updatedItems.append(.updated(at: updated.offset))
                        foundUpdated = true
                    }
                }
            }
        }

        let allChanges = [insertedItems, removedItems, updatedItems, movedItems].flatMap { $0 }
        return CollectionChanges(allChanges: allChanges)
    }
}
