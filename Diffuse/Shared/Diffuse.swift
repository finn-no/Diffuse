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
            let removed = old.enumerated().map({ offset, _ in return offset })
            return CollectionChanges(removed: removed)
        } else if old.isEmpty {
            let inserted = new.enumerated().map({ offset, _ in return offset })
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
        var oldChanges = [T: Int]() // [Value: Change]
        var oldValues = [Int: T]() // [Offset: Value]
        var moved = [Move<Int>]()
        var updated = [Int]()
        var inserted = [Int]()

        // 5. Iterate over the array of differences (remember that it's sorted, so the old items come first).
        for item in difference {
            if item.isNew {
                if let offset = oldChanges[item.value] {
                    // 5.1. MOVE - if the given value exists both in the new and the old sets of changes.
                    moved.append(Move(from: offset, to: item.offset))
                    oldChanges.removeValue(forKey: item.value)
                    oldValues.removeValue(forKey: offset)
                } else {
                    newItems.append(item)
                }
            } else {
                // 5.2. REMOVE - Assume that the old item has been removed.
                oldChanges[item.value] = item.offset
                // Set value for the given offset (used for checking for updates leter).
                oldValues[item.offset] = item.value
            }
        }

        // 6. Iterate over the array of new items (extracted from the array of differences).
        for item in newItems {
            if let value = oldValues[item.offset] {
                // 6.1. UPDATE - if the given offset exists both in the new and the old sets of changes.
                updated.append(item.offset)
                oldChanges.removeValue(forKey: value)
                oldValues.removeValue(forKey: item.offset)
            } else {
                // 6.2. INSERT - if neither value nor offset exists in the old set of changes.
                inserted.append(item.offset)
            }
        }

        return CollectionChanges(inserted: inserted, removed: Array(oldChanges.values), moved: moved, updated: updated)
    }

    public static func diff22<T: Hashable>(old: [T], new: [T]) -> CollectionChanges {

        if old.isEmpty {
            return CollectionChanges(inserted: Array(0 ..< new.count))
        } else if new.isEmpty {
            return CollectionChanges(removed: Array(0 ..< old.count))
        }

        let size = max(old.count, new.count)

        var tempArray = Array<Operation<T>?>(repeating: nil, count: size)
        var updates = Set<Operation<T>>(minimumCapacity: size)
        var removes = Set<Operation<T>>(minimumCapacity: size)
        var inserts = Set<Operation<T>>(minimumCapacity: size)
        var moves = Set<Operation<T>>(minimumCapacity: size)

        for i in 0 ..< size {
            if i < old.count, i < new.count {
                guard old[i] != new[i] else { continue }

                let removeOp = Operation(value: old[i], removed: i)
                let insertOp = Operation(value: new[i], inserted: i)

                if let moved = inserts.remove(removeOp) {
                    moves.insert(Operation(value: old[i], moved: (removeOp.removed, moved.inserted)))
                    tempArray[moved.inserted] = nil
                } else { removes.insert(removeOp) }

                if let moved = removes.remove(insertOp) { moves.insert(Operation(value: new[i], moved: (moved.removed, insertOp.inserted))) }
                else {
                    inserts.insert(insertOp)
                    tempArray[i] = insertOp
                }

                continue
            }

            if i < old.count {
                let removeOp = Operation(value: old[i], removed: i)
                if let moved = inserts.remove(removeOp) {
                    moves.insert(Operation(value: old[i], moved: (removeOp.removed, moved.inserted)))
                    tempArray[moved.inserted] = nil
                }
                else { removes.insert(removeOp) }
                continue
            }

            if i < new.count {
                let insertOp = Operation(value: new[i], inserted: i)
                if let moved = removes.remove(insertOp) { moves.insert(Operation(value: new[i], moved: (moved.removed, insertOp.inserted))) }
                else { inserts.insert(insertOp) }
                continue
            }
        }

        removes.forEach { op in
            guard let updated = tempArray[op.removed] else { return }
            removes.remove(op)
            inserts.remove(updated)
            updates.insert(Operation(value: updated.value, updated: updated.inserted))
        }

        let inserted = inserts.map { $0.inserted }
        let removed = removes.map { $0.removed }
        let moved = moves.map { $0.moved }
        let updated = updates.map { $0.updated }

        return CollectionChanges(inserted: inserted, removed: removed, moved: moved, updated: updated)
    }

    public static func diff2<T: Hashable>(old: [T], new: [T]) -> CollectionChanges {

        if old.isEmpty {
            return CollectionChanges(inserted: Array(0 ..< new.count))
        } else if new.isEmpty {
            return CollectionChanges(removed: Array(0 ..< old.count))
        }

        let minSize = min(old.count, new.count)

        var startIndex = 0
        for i in 0 ..< minSize {
            if new[i] != old[i] {
                startIndex = i
                break
            }
        }

        var oldSet = Set<Element<T>>(minimumCapacity: old.count)
        for i in startIndex ..< old.count { oldSet.insert(Element(value: old[i], index: i)) }

        var moved = [Move<Int>]()
        moved.reserveCapacity(minSize)

        var inserted = Set<Int>(minimumCapacity: new.count)

        for i in startIndex ..< new.count {
            let element = Element(value: new[i], index: i)
            if let m = oldSet.remove(element) {
                guard m.index != i else { continue }
                moved.append((from: m.index, to: element.index))
            } else {
                inserted.insert(i)
            }
        }

        var removed = [Int]()
        removed.reserveCapacity(old.count)

        var updated = [Int]()
        updated.reserveCapacity(minSize)

        for element in oldSet {
            if let update = inserted.remove(element.index) {
                updated.append(update)
            } else {
                removed.append(element.index)
            }
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

struct Operation<T: Hashable>: Hashable {
    let value: T
    let removed: Int
    let inserted: Int
    let moved: Move<Int>
    let updated: Int

    init(value: T, removed: Int = -1, inserted: Int = -1, moved: Move<Int> = (-1, -1), updated: Int = -1) {
        self.value = value
        self.removed = removed
        self.inserted = inserted
        self.moved = moved
        self.updated = updated
    }

    var hashValue: Int {
        return value.hashValue
    }

    static func == (lhs: Operation<T>, rhs: Operation<T>) -> Bool {
        return lhs.value == rhs.value
    }
}
