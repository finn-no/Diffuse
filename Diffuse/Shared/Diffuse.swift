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

        let allChanges = [insertedItems, removedItems, updatedItems, movedItems].flatMap { $0 }
        return CollectionChanges(allChanges: allChanges)
    }

    public func diff<T: Hashable>(old: [T], new: [T]) -> CollectionChanges {
        if new.isEmpty {
            let changes = old.enumerated().map({ offset, _ in return Change.remove(row: offset) })
            return CollectionChanges(allChanges: changes)
        } else if old.isEmpty {
            let changes = new.enumerated().map({ offset, _ in return Change.insert(row: offset) })
            return CollectionChanges(allChanges: changes)
        }

        let oldSet = Set(old.enumerated().map { offset, element in
            return Item(value: element, offset: offset, isNew: false)
        })

        let newSet = Set(new.enumerated().map { offset, element in
            return Item(value: element, offset: offset, isNew: true)
        })

        /// A set with the elements that are either in the new set or in the old set, but not in both.
        let difference = Array(newSet.symmetricDifference(oldSet)).sorted(by: { $0.offset < $1.offset })
        var newItems = [Item<T>]()
        var oldChanges = [T: Change]() // [Value: Change]
        var oldValues = [Int: T]() // [Offset: Value]
        var changes = [Change]()

        // Split old and new items
        for element in difference {
            if element.isNew {
                newItems.append(element)
            } else {
                // Assume that the old item has been removed
                oldChanges[element.value] = .remove(row: element.offset)
                // Set value for the given offset
                oldValues[element.offset] = element.value
            }
        }

        for element in newItems {
            if case .remove(let offset)? = oldChanges[element.value] {
                // MOVE - if the given value exists both in the new and the old sets of changes
                changes.append(.move(fromRow: offset, toRow: element.offset))
                oldChanges.removeValue(forKey: element.value)
                oldValues.removeValue(forKey: element.offset)
            } else if let value = oldValues[element.offset] {
                // UPDATE - if the given offset exists both in the new and the old sets of changes
                changes.append(.updated(row: element.offset))
                oldChanges.removeValue(forKey: value)
                oldValues.removeValue(forKey: element.offset)
            } else {
                // INSERT - if neither value nor offset exists in the old set of changes
                changes.append(.insert(row: element.offset))
            }
        }

        changes.append(contentsOf: Array(oldChanges.values))

        return CollectionChanges(allChanges: changes)
    }
}
