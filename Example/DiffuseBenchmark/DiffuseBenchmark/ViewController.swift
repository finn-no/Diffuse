//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import UIKit
import Diffuse
import Differific
import DeepDiff

final class ViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        print("Start...")

        runBenchmarks(count: 10)
        runBenchmarks(count: 100)
        runBenchmarks(count: 1000)
        runBenchmarks(count: 10000)
        runBenchmarks(count: 20000)
        runBenchmarks(count: 50000)
        runBenchmarksWithEmptyOldArray(newCount: 1000)
        runBenchmarksWithEmptyNewArray(oldCount: 1000)

        print("Done.")
    }

    // MARK: - Private

    private func runBenchmarks(count: Int) {
        let (old, new) = generate(count: count)
        runBenchmarks(old: old, new: new)
    }

    private func runBenchmarksWithEmptyOldArray(newCount: Int) {
        let (_, new) = generate(count: newCount)
        runBenchmarks(old: [], new: new)
    }

    private func runBenchmarksWithEmptyNewArray(oldCount: Int) {
        let (old, _) = generate(count: oldCount)
        runBenchmarks(old: old, new: [])
    }

    private func runBenchmarks(old: [Int], new: [Int]) {
        print("\nBenchmark: \(old.count) old, \(new.count) new elements\n")

        let benchmarks = Algorithm.allCases.map(Benchmark.init)

        // Call the diff function of every algorithm with the same input 10 times and calculate the average.
        for _ in 0...10 {
            for benchmark in benchmarks {
                benchmark.peformDiff(old: old, new: new)
            }
        }

        for (offset, benchmark) in benchmarks.sorted(by: { $0.average < $1.average }).enumerated() {
            print("\(offset + 1). \(benchmark.algorithm.rawValue): \(benchmark.average)s")
        }
    }

    private func generate(count: Int) -> (old: [Int], new: [Int]) {
        let old = Array(0..<count)
        var new = old
        let lowerBound = count / 10
        let upperBound = lowerBound * 2
        let range = lowerBound..<upperBound

        new.removeSubrange(range)

        for i in range {
            new.append(count + i)
        }

        return (old: old, new: new)
    }
}

// MARK: - Custom types

private enum Algorithm: String, CaseIterable {
    case diffuse = "Diffuse"
    case diffuse = "Diffuse"
    case differific = "Differific"
    case deepDiff = "DeepDiff"

    func diffFunction(old: [Int], new: [Int]) -> () -> Void {
        switch self {
        case .diffuse:
            return { _ = diff(old: old, new: new) }
        case .diffuse2:
            return { _ = diff2(old: old, new: new) }
        case .differific:
            return { _ = DiffManager().diff(old, new) }
        case .deepDiff:
            return { _ = DeepDiff.diff(old: old, new: new) }
        }
    }
}

private final class Benchmark {
    let algorithm: Algorithm
    private var timeIntervals = [TimeInterval]()

    var average: TimeInterval {
        return timeIntervals.average
    }

    init(algorithm: Algorithm) {
        self.algorithm = algorithm
    }

    func peformDiff(old: [Int], new: [Int]) {
        let start = Date()
        algorithm.diffFunction(old: old, new: new)()
        let end = Date()
        let timeInterval = end.timeIntervalSince1970 - start.timeIntervalSince1970
        timeIntervals.append(timeInterval)
    }
}

// MARK: - Private extensions

private extension Collection where Element: Numeric {
    var total: Element { return reduce(0, +) }
}

private extension Collection where Element: BinaryFloatingPoint {
    var average: Element {
        return isEmpty ? 0 : total / Element(count)
    }
}

public func diff<T: Hashable>(old: [T], new: [T]) -> CollectionChanges {
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

public func diff2<T: Hashable>(old: [T], new: [T]) -> CollectionChanges {
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


struct Element<T: Hashable>: Hashable {
    let value: T
    let index: Int

    var hashValue: Int {
        return value.hashValue
    }

    static func == (lhs: Element<T>, rhs: Element<T>) -> Bool {
        return lhs.value == rhs.value
    }
}

public typealias Move<T> = (from: T, to: T)

