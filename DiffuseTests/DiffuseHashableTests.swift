//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import XCTest
@testable import Diffuse

class DiffuseHashableTests: XCTestCase {
    struct Object: Hashable {
        let objId: Int
        var name: String
    }

    func testEmptyOldEmptyNew() {
        let old = [Int]()
        let new = [Int]()
        let changes = Diffuse.diff(old: old, new: new)

        // Both collections are empty.
        XCTAssertEqual(0, changes.count)
    }

    // MARK: - Comparing primitives

    func testEmptyOldWithPrimitives() {
        let old = [Int]()
        let new = [1, 2, 3]
        let changes = Diffuse.diff(old: old, new: new)

        // Only insertions has occured.
        XCTAssertEqual(3, changes.count)
        XCTAssertEqual(3, changes.inserted.count)
    }

    func testEmptyNewWithPrimitives() {
        let old = [1, 2, 3]
        let new = [Int]()
        let changes = Diffuse.diff(old: old, new: new)

        // Only removals has occured.
        XCTAssertEqual(3, changes.count)
        XCTAssertEqual(3, changes.removed.count)
    }

    func testInsertWithPrimitives() {
        let old = [1, 2, 3]
        let new = [1, 4, 2, 3, 5]
        let changes = Diffuse.diff(old: old, new: new)

        // Number 4 is inserted at index `1`, which means two items (number 2 and 3) have been pushed/moved.
        // The total number of changes should equal 4.
        XCTAssertEqual(4, changes.count)
        XCTAssertEqual(2, changes.inserted.count)
        XCTAssertEqual(2, changes.moved.count)
    }

    func testRemoveWithPrimitives() {
        let old = [1, 2, 3, 4, 5]
        let new = [1, 3, 5]
        let changes = Diffuse.diff(old: old, new: new)

        // Two items are removed, but that also means two items (number 3 and 5) have been pulled/moved.
        // The total number of changes should equal 4.
        XCTAssertEqual(4, changes.count)
        XCTAssertEqual(2, changes.removed.count)
        XCTAssertEqual(2, changes.moved.count)
    }

    func testMoveWithPrimitives() {
        let old = [1, 2, 3, 4, 5]
        let new = [5, 1, 3, 2, 4]
        let changes = Diffuse.diff(old: old, new: new)

        // The only item in its original position is the number 3. The rest have been moved.
        XCTAssertEqual(4, changes.count)
        XCTAssertEqual(4, changes.moved.count)
    }

    func testUpdateWithPrimitives() {
        let old = [1, 2, 3, 4, 5]
        let new = [1, 2, 3, 6, 5]
        let changes = Diffuse.diff(old: old, new: new)

        // The only item has been updated
        XCTAssertEqual(1, changes.count)
        XCTAssertEqual(1, changes.updated.count)
    }

    func testMultipleOperationsWithPrimitives() {
        let old = [0, 1, 2]

        // Move `2`
        //      = 1 change (move)
        // Insert `4` and `5`
        //      = 2 changes (inserts)
        // Remove `0` and insert `3`
        //      = 3 changes (remove, move and insert)
        let new = [1, 3, 4, 2, 5]
        let changes = Diffuse.diff(old: old, new: new)

        XCTAssertEqual(6, changes.count)
        XCTAssertEqual(2, changes.moved.count)
        XCTAssertEqual(3, changes.inserted.count)
        XCTAssertEqual(1, changes.removed.count)
        XCTAssertEqual(0, changes.updated.count)
    }

    // MARK: - Comparing complex structures

    func testInsertWithCustomType() {
        let objects = createObjects()
        let old = objects
        var new = objects

        // Insert 2 new Objects. One at index 1, and one at the end.
        new.insert(Object(objId: 4, name: "E"), at: 1)
        new.append(Object(objId: 5, name: "F"))

        let changes = Diffuse.diff(old: old, new: new)

        // `E` is inserted at index `1`, which means three items (`B`, `C` and `D`) have been pushed/moved.
        // The total number of changes should equal 5.
        XCTAssertEqual(5, changes.count)
        XCTAssertEqual(2, changes.inserted.count)
        XCTAssertEqual(3, changes.moved.count)
    }

    func testRemoveWithCustomType() {
        let objects = createObjects()
        let old = objects
        var new = objects

        // Remove two objects.
        new.remove(at: 1)
        new.remove(at: 1)

        let changes = Diffuse.diff(old: old, new: new)

        // Two objects (`B` and `C`) are removed, which also means one item (`D`) have been pulled/moved.
        // The total number of changes should equal 3.
        XCTAssertEqual(3, changes.count)
        XCTAssertEqual(2, changes.removed.count)
        XCTAssertEqual(1, changes.moved.count)
    }

    func testUpdateWithCustomType() {
        let objects = createObjects()
        let old = objects
        var new = objects

        // Update two objects.
        new[1].name = "New name"
        new[3].name = "New name"

        let changes = Diffuse.diff(old: old, new: new)

        XCTAssertEqual(2, changes.updated.count)
        XCTAssertEqual(2, changes.count)
    }

    func testMultipleOperationsWithCustomType() {
        let objectA = Object(objId: 0, name: "A")
        var objectB = Object(objId: 1, name: "B")
        let objectC = Object(objId: 2, name: "C")
        let objectD = Object(objId: 3, name: "D")
        let objectE = Object(objId: 4, name: "E")
        let objectF = Object(objId: 5, name: "F")
        let old = [objectA, objectB, objectC]

        // Move `C`
        //      = 1 change (move)
        // Insert `E` and `F`
        //      = 2 changes (inserts)
        // Remove `A` and insert `D`
        //      = 2 changes (updates)
        //        Index 0 and 1 are both considered updated.
        //
        //        "But, why? `A` is removed, `B` is updated and moved to index 0 and `D` is inserted at index 1, this should be
        //        one delete, one update, one move and one insert, right?"
        //
        //        Nope.
        //        We're using `hashValue` to compare elements, so `B` is actually considered to be a new element since it's
        //        `hashValue` has changed because of the update. This means that the algorithm now thinks two deletions and
        //        two insertions has happened instead. Both `A` and `old B` are considered removed from index 0 and 1, and new
        //        elements are inserted to index 0 and 1 (`new B` and `D`).
        //        For better UX when updating ie. a `UITableView` we've decided that a removal and an insertion on the same
        //        index is to be considered an update.
        objectB.name = "New name"

        let new = [objectB, objectD, objectE, objectC, objectF]
        let changes = Diffuse.diff(old: old, new: new)

        XCTAssertEqual(5, changes.count)
        XCTAssertEqual(1, changes.moved.count)
        XCTAssertEqual(2, changes.inserted.count)
        XCTAssertEqual(2, changes.updated.count)
        XCTAssertEqual(0, changes.removed.count)
    }

    // MARK: - Helpers

    private func createObjects() -> [Object] {
        let names = ["A", "B", "C", "D"]
        return names.enumerated().map { Object(objId: $0.offset, name: $0.element)}
    }
}
