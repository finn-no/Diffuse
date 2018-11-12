//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import Foundation

public struct Diffuse {
    private init() {}

    public static func diff<T: Equatable>(old: [T], new: [T], comparator: (T, T) -> Bool) -> CollectionChanges {
        let oldEnumerated = old.enumerated()
        let updatedEnumerated = new.enumerated()

        var insertedItems = [Change]()
        var removedItems = [Change]()
        var updatedItems = [Change]()
        var movedItems = [Change]()

        // DELETED - Find indices which are represented in `oldItems`, but not in `updatedItems`.
        for old in oldEnumerated {
            guard !updatedEnumerated.contains(where: { comparator($0.element, old.element) }) else { continue }
            removedItems.append(Change.remove(row: old.offset))
        }

        for updated in updatedEnumerated {
            var foundMoved = false
            var foundUpdated = false

            // INSERTED - Find indices which are represented in `updatedItems`, but not in `oldItems`.
            if !oldEnumerated.contains(where: { comparator($0.element, updated.element) }) {
                insertedItems.append(Change.insert(row: updated.offset))

                // If an item is inserted, it will definitely not be either modified or updated. Skip to next iteration.
                continue
            }

            for old in oldEnumerated {
                // Stop iterating `oldEnumerated` if we know the element is both updated and moved.
                if foundUpdated && foundMoved { break }

                if comparator(old.element, updated.element) {
                    // MOVED - Find elements which exists in both `oldItems` and `updatedItems`, but have
                    // a different index.
                    if !foundMoved && old.offset != updated.offset {
                        movedItems.append(.move(fromRow: old.offset, toRow: updated.offset))
                        foundMoved = true
                    }

                    // UPDATED - Find elements where `comparator` returns `true`, but the elements themselves
                    // don't match.
                    if !foundUpdated && old.element != updated.element {
                        updatedItems.append(.updated(row: updated.offset))
                        foundUpdated = true
                    }
                }
            }
        }

        return CollectionChanges(inserted: insertedItems, removed: removedItems, moved: movedItems, updated: updatedItems)
    }

    public static func diff<T: Hashable>(old: [T], new: [T]) -> CollectionChanges {
        // 1. Early return if either the new or the old array is empty.
        if new.isEmpty {
            let removed = old.enumerated().map({ offset, _ in return Change.remove(row: offset) })
            return CollectionChanges(removed: removed)
        } else if old.isEmpty {
            let inserted = new.enumerated().map({ offset, _ in return Change.insert(row: offset) })
            return CollectionChanges(inserted: inserted)
        }

        // 2. Map both arrays to sets of `Item<T>` type.
        let oldSet = Set(old.enumerated().map { offset, element in
            return Item(value: element, offset: offset, isNew: false)
        })

        let newSet = Set(new.enumerated().map { offset, element in
            return Item(value: element, offset: offset, isNew: true)
        })

        // 3. Get an array with the elements that are either in the new set or in the old set, but not in both.
        // 4. Sort by offset where old items come first.
        let difference = Array(newSet.symmetricDifference(oldSet)).sorted(by: {
            if $0.isNew == $1.isNew {
                return $0.offset < $1.offset
            }
            return !$0.isNew && $1.isNew
        })

        var newItems = [Item<T>]()
        var oldChanges = [T: Change]() // [Value: Change]
        var oldValues = [Int: T]() // [Offset: Value]
        var moved = [Change]()
        var updated = [Change]()
        var inserted = [Change]()

        // 5. Iterate over the array of differences (remember that it's sorted, so the old items come first).
        for item in difference {
            if item.isNew {
                if case .remove(let offset)? = oldChanges[item.value] {
                    // 5.1. MOVE - if the given value exists both in the new and the old sets of changes.
                    moved.append(.move(fromRow: offset, toRow: item.offset))
                    oldChanges.removeValue(forKey: item.value)
                    oldValues.removeValue(forKey: offset)
                } else {
                    newItems.append(item)
                }
            } else {
                // 5.2. REMOVE - Assume that the old item has been removed.
                oldChanges[item.value] = .remove(row: item.offset)
                // Set value for the given offset (used for checking for updates leter).
                oldValues[item.offset] = item.value
            }
        }

        // 6. Iterate over the array of new items (extracted from the array of differences).
        for item in newItems {
            if let value = oldValues[item.offset] {
                // 6.1. UPDATE - if the given offset exists both in the new and the old sets of changes.
                updated.append(.updated(row: item.offset))
                oldChanges.removeValue(forKey: value)
                oldValues.removeValue(forKey: item.offset)
            } else {
                // 6.2. INSERT - if neither value nor offset exists in the old set of changes.
                inserted.append(.insert(row: item.offset))
            }
        }

        return CollectionChanges(inserted: inserted, removed: Array(oldChanges.values), moved: moved, updated: updated)
    }
}
