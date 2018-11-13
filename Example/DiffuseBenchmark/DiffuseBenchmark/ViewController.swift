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
        print("Benchmark: \(old.count) old, \(new.count) new elements\n")

        var benchmarks = [Benchmark]()

        benchmarks.append(Benchmark(name: "Diffuse old", execute: {
            _ = Diffuse.diff(old: old, new: new)
        }))

        benchmarks.append(Benchmark(name: "Differific", execute: {
            _ = DiffManager().diff(old, new)
        }))

        benchmarks.append(Benchmark(name: "DeepDiff", execute: {
            _ = DeepDiff.diff(old: old, new: new)
        }))

        for (offset, benchmark) in benchmarks.sorted(by: { $0.timeInterval < $1.timeInterval }).enumerated() {
            print("\(offset + 1). \(benchmark.name): \(benchmark.timeInterval)s")
        }

        print("\n")
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

private struct Benchmark {
    let name: String
    let timeInterval: TimeInterval

    init(name: String, execute: () -> Void) {
        self.name = name
        let start = Date()
        execute()
        let end = Date()
        timeInterval =  end.timeIntervalSince1970 - start.timeIntervalSince1970
    }
}
