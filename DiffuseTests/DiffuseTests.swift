//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import XCTest
@testable import Diffuse

class DiffuseTests: XCTestCase {
    struct Object: Equatable {
        let id: Int
        var name: String
    }

    // MARK: - Default comparator

    func testInsert_withDefaultComparator() {
        let old = [1, 2, 3]
        let updated = [1, 4, 2, 3, 5]

        let changes = Diffuse.diff(old: old, updated: updated)

        XCTAssertEqual(2, changes.inserted.count)

        // Number 4 is inserted at index `1`, which means two items (number 2 and 3) have been pushed/moved.
        // The total number of changes should equal 4.
        XCTAssertEqual(4, changes.allChanges.count)
        XCTAssertEqual(2, changes.moved.count)
    }

    func testRemove_withDefaultComparator() {
        let old = [1, 2, 3, 4, 5]
        let updated = [1, 3, 5]

        let changes = Diffuse.diff(old: old, updated: updated)

        XCTAssertEqual(2, changes.removed.count)

        // Two items are removed, but that also means two items (number 3 and 5) have been pulled/moved.
        // The total number of changes should equal 4.
        XCTAssertEqual(4, changes.allChanges.count)
        XCTAssertEqual(2, changes.moved.count)
    }

    func testMove_withDefaultComparator() {
        let old = [1, 2, 3, 4, 5]
        let updated = [5, 1, 3, 2, 4]

        let changes = Diffuse.diff(old: old, updated: updated)

        // The only item in its original position is the number 3. The rest have been moved.
        XCTAssertEqual(4, changes.allChanges.count)
        XCTAssertEqual(4, changes.moved.count)
    }

    // MARK: - Structs and custom comparator

    func createObjects() -> [Object] {
        let names = ["A", "B", "C", "D"]
        return names.enumerated().map { Object(id: $0.offset, name: $0.element)}
    }

    func testInsert_withCustomComparator() {
        let objects = createObjects()

        let old = objects
        var updated = objects

        // Insert 2 new Objects. One at index 1, and one at the end.
        updated.insert(Object(id: 4, name: "E"), at: 1)
        updated.append(Object(id: 5, name: "F"))

        let changes = Diffuse.diff(old: old, updated: updated, comparator: { $0.id == $1.id })

        XCTAssertEqual(2, changes.inserted.count)

        // `ObjectE` is inserted at index `1`, which means three items (`ObjectB`, `ObjectC` and `ObjectD`) have been pushed/moved.
        // The total number of changes should equal 5.
        XCTAssertEqual(5, changes.allChanges.count)
        XCTAssertEqual(3, changes.moved.count)
    }

    func testRemove_withCustomComparator() {
        let objects = createObjects()

        let old = objects
        var updated = objects

        // Remove two objects.
        updated.remove(at: 1)
        updated.remove(at: 1)

        let changes = Diffuse.diff(old: old, updated: updated, comparator: { $0.id == $1.id })

        XCTAssertEqual(2, changes.removed.count)

        // Two objects (`ObjectB` and `ObjectC`) are removed, which also means one item (`ObjectD`) have been pulled/moved.
        // The total number of changes should equal 3.
        XCTAssertEqual(3, changes.allChanges.count)
        XCTAssertEqual(1, changes.moved.count)
    }

    func testUpdate_withCustomComparator() {
        let objects = createObjects()

        let old = objects
        var updated = objects

        // Update two objects.
        updated[1].name = "New name"
        updated[3].name = "New name"

        let changes = Diffuse.diff(old: old, updated: updated, comparator: { $0.id == $1.id })

        XCTAssertEqual(2, changes.updated.count)
        XCTAssertEqual(2, changes.allChanges.count)
    }

    // MARK: - Multiple operations

    func testMultipleOperations_withCustomComparator() {
        let objectA = Object(id: 0, name: "A")
        var objectB = Object(id: 1, name: "B")
        let objectC = Object(id: 2, name: "C")
        let objectD = Object(id: 3, name: "D")
        let objectE = Object(id: 4, name: "E")
        let objectF = Object(id: 5, name: "F")

        let old = [objectA, objectB, objectC]

        // Remove `ObjectA`
        //      = 1 change (remove + pull/move `ObjectB` to index 0)
        // Update `ObjectB`
        //      = 1 change
        // Insert `ObjectD` and `ObjectE` before `ObjectC`
        //      = 3 changes (2 inserts + push/move `ObjectC`)
        // Insert `ObjectF` after `ObjectC`
        //      = 1 change
        objectB.name = "New name"
        let updated = [objectB, objectD, objectE, objectC, objectF]

        let changes = Diffuse.diff(old: old, updated: updated, comparator: { $0.id == $1.id })

        XCTAssertEqual(7, changes.allChanges.count)
        XCTAssertEqual(3, changes.inserted.count)
        XCTAssertEqual(1, changes.removed.count)
        XCTAssertEqual(2, changes.moved.count)
        XCTAssertEqual(1, changes.updated.count)
    }
}
