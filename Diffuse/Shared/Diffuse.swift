//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import Foundation

public struct Diffuse {
    private init() {}

    /// Use this method to find the difference between two collections. Accepts a closure to compare elements
    /// from each collection.
    ///
    /// Use this method if the elements has some form of unique identifier you want to use to compare equality.
    ///
    ///
    /// - Parameters:
    ///   - old: The old collection.
    ///   - new: The updated collection.
    ///   - comparator: A closure that takes one element from each collection as its arguments and returns a
    ///     Boolean value indicating whether the elements are a match.
    public static func diff<T: Equatable>(old: [T], new: [T], comparator: (T, T) -> Bool) -> CollectionChanges {
        let oldEnumerated = old.enumerated()
        let updatedEnumerated = new.enumerated()

        var insertedItems = [Int]()
        var removedItems = [Int]()
        var updatedItems = [Int]()
        var movedItems = [Move<Int>]()

        // DELETED - Find indices which are represented in `oldItems`, but not in `updatedItems`.
        for old in oldEnumerated {
            guard !updatedEnumerated.contains(where: { comparator($0.element, old.element) }) else { continue }
            removedItems.append(old.offset)
        }

        for updated in updatedEnumerated {
            var foundMoved = false
            var foundUpdated = false

            // INSERTED - Find indices which are represented in `updatedItems`, but not in `oldItems`.
            if !oldEnumerated.contains(where: { comparator($0.element, updated.element) }) {
                insertedItems.append(updated.offset)

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
                        movedItems.append(Move(from: old.offset, to: updated.offset))
                        foundMoved = true
                    }

                    // UPDATED - Find elements where `comparator` returns `true`, but the elements themselves
                    // don't match.
                    if !foundUpdated && old.element != updated.element {
                        updatedItems.append(updated.offset)
                        foundUpdated = true
                    }
                }
            }
        }

        return CollectionChanges(inserted: insertedItems, removed: removedItems, moved: movedItems, updated: updatedItems)
    }

    public static func diff<T: Hashable>(old: [T], new: [T]) -> CollectionChanges {
        // 1 - We can return early in some cases
        if old.isEmpty { return CollectionChanges(inserted: Array(0..<new.count)) }
        if new.isEmpty { return CollectionChanges(removed: Array(0..<old.count)) }

        // This is useful when reserving memory
        let minSize = min(old.count, new.count)

        // Setup the arrays for all the operations
        var inserted = Set<Int>(minimumCapacity: new.count) // Make inserted a set for now, makes it faster to find updated elements
        var removed = [Int]()
        var moved = [Move<Int>]()
        var updated = [Int]()

        // We can't remove more items than the amount of element in 'old'
        removed.reserveCapacity(old.count)
        moved.reserveCapacity(minSize)
        updated.reserveCapacity(minSize)

        // 2 - Skip all the equal elements in the beginning of the arrays
        var startIndex = 0
        for i in 0..<minSize {
            if new[i] != old[i] {
                // These are the first two elements which are different
                startIndex = i
                break
            }
        }

        // 3 - Make the old array a set for fast lookup on values
        var oldSet = Set<Element<T>>(minimumCapacity: old.count)
        for i in startIndex..<old.count {
            oldSet.insert(Element(value: old[i], index: i))
        }

        // 4 - Iterate the 'new' array and compare against elements in 'oldSet'
        for i in startIndex ..< new.count {
            // 4.1 - Need to create elements to compare elements in the 'oldSet'
            let element = Element(value: new[i], index: i)

            // 4.2 - Search for 'element' in the 'oldSet'
            if let movedElement = oldSet.remove(element) {
                // If we find 'element' in the 'oldSet', it could have been moved
                // 'element' has only moved if the index has changed
                if movedElement.index != i {
                    // The indeces are different so 'element' has moved
                    moved.append((from: movedElement.index, to: element.index))
                }
            } else {
                // If 'element' is not in 'oldSet' is has been inserted into the 'new' array
                inserted.insert(i)
            }
        }

        // 5 - Find elements that are updated
        for element in oldSet {
            if let update = inserted.remove(element.index) {
                // If we find 'element.index' in 'inserted', there has been a remove and insert at the same index
                // and we can consider 'element' as updated
                updated.append(update)
            } else {
                // If 'element.index' is not in 'inserted' it has been removed from 'old'
                removed.append(element.index)
            }
        }

        // 6 - Convert 'inserted' to an array and return with the other operations
        return CollectionChanges(inserted: Array<Int>(inserted), removed: removed, moved: moved, updated: updated)
    }
}

struct Element<T: Hashable>: Hashable {
    let value: T
    let index: Int

    var hashValue: Int {
        return value.hashValue
    }

    static func ==(lhs: Element<T>, rhs: Element<T>) -> Bool {
        return lhs.value == rhs.value
    }
}
