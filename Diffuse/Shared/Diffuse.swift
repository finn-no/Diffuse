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
        // 1. Early return if either the new or the old array is empty.
        if new.isEmpty {
            return CollectionChanges(removed: Array(0..<old.count))
        } else if old.isEmpty {
            return CollectionChanges(inserted: Array(0..<new.count))
        }

        var removedOffsets = [Int: Int]() // [HashValue: Offset] of removed elements.
        var removedHashValues = [Int: Int]() // [Offset: HashValue] of removed elements.
        var updatedAndInsertedOffsets = [Int]() // Offsets for updated and inserted elements.
        var inserted = [Int]()
        var moved = [Move<Int>]()
        var updated = [Int]()

        // Exlude an element with the given hash value and offset from being marked as removed.
        func excludeRemoved(hashValue: Int, offset: Int) {
            removedOffsets.removeValue(forKey: hashValue)
            removedHashValues.removeValue(forKey: offset)
        }

        // 2. Iterate over the array of old elements.
        var offset = 0
        for element in old {
            defer { offset += 1 }
            // 2.1. REMOVE - Assume that the old item has been removed.
            let hashValue = element.hashValue
            removedOffsets[hashValue] = offset
            removedHashValues[offset] = hashValue
        }

        // 3. Iterate over the array of new elements.
        offset = 0
        for element in new {
            defer { offset += 1 }

            if let oldOffset = removedOffsets[element.hashValue] {
                // 3.1. MOVE - if the given element exists both in the new and the old arrays.
                if oldOffset != offset {
                    moved.append(Move(from: oldOffset, to: offset))
                }
                excludeRemoved(hashValue: element.hashValue, offset: oldOffset)
            } else {
                // 3.2. Append to the array of offsets for updates and inserts.
                updatedAndInsertedOffsets.append(offset)
            }
        }

        // 4. Iterate over the array of offsets for updates and inserts.
        for offset in updatedAndInsertedOffsets {
            if let hashValue = removedHashValues[offset] {
                // 4.1. UPDATE - if the given offset also exists in the array of removed elements.
                // remove(n) + insert(n) = update(n)
                updated.append(offset)
                excludeRemoved(hashValue: hashValue, offset: offset)
            } else {
                // 4.2. INSERT - if neither element nor offset exists in the old array.
                inserted.append(offset)
            }
        }

        return CollectionChanges(inserted: inserted, removed: Array(removedHashValues.keys), moved: moved, updated: updated)
    }

    public static func diff2<T: Hashable>(old: [T], new: [T]) -> CollectionChanges {

        // Special cases
        if old.isEmpty { return CollectionChanges(inserted: Array(0 ..< new.count)) }
        else if new.isEmpty { return CollectionChanges(removed: Array(0 ..< old.count)) }

        let minSize = min(old.count, new.count)

        // Start searching at the first change
        var startIndex = 0
        for i in 0 ..< minSize {
            if new[i] != old[i] {
                startIndex = i
                break
            }
        }

        // Make the old array a set for fast search of value type
        var oldSet = Set<Element<T>>(minimumCapacity: old.count)
        for i in startIndex ..< old.count { oldSet.insert(Element(value: old[i], index: i)) }

        var moved = [Move<Int>]()
        moved.reserveCapacity(minSize)

        // Make inserted a set for now, makes it faster to find updated elements
        var inserted = Set<Int>(minimumCapacity: new.count)

        for i in startIndex ..< new.count {
            let element = Element(value: new[i], index: i)
            // If we find the element in the oldSet it could have been moved
            if let m = oldSet.remove(element) {
                // The element is only moved if the index has changed
                guard m.index != i else { continue }
                // This element has been moved
                moved.append((from: m.index, to: element.index))
            } else {
                // If we can't find the element it has been inserted
                inserted.insert(i)
            }
        }

        var removed = [Int]()
        removed.reserveCapacity(old.count)

        var updated = [Int]()
        updated.reserveCapacity(minSize)

        for element in oldSet {
            // If there is an item allready inserted at elements index it has been updated
            if let update = inserted.remove(element.index) { updated.append(update) }
            // If not the element has been removed
            else { removed.append(element.index) }
        }

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
