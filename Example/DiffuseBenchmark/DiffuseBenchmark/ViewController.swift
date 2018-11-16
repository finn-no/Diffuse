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
    case differific = "Differific"
    case deepDiff = "DeepDiff"

    func diffFunction(old: [Int], new: [Int]) -> () -> Void {
        switch self {
        case .diffuse:
            return { _ = diff(old: old, new: new) }
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
