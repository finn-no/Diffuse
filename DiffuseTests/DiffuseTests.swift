//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import XCTest
@testable import Diffuse

class DiffuseTests: XCTestCase {
    struct Object: Equatable {
        let objId: Int
        var name: String
    }

    // MARK: - Primitives

    func testInsert_withPrimitives() {
        let old = [1, 2, 3]
        let new = [1, 4, 2, 3, 5]
        let changes = Diffuse.diff(old: old, new: new, comparator: { $0 == $1 })

        // Number 4 is inserted at index `1`, which means two items (number 2 and 3) have been pushed/moved.
        // The total number of changes should equal 4.
        XCTAssertEqual(4, changes.allChanges.count)
        XCTAssertEqual(2, changes.inserted.count)
        XCTAssertEqual(2, changes.moved.count)
    }

    func testRemove_withPrimitives() {
        let old = [1, 2, 3, 4, 5]
        let new = [1, 3, 5]
        let changes = Diffuse.diff(old: old, new: new, comparator: { $0 == $1 })

        // Two items are removed, but that also means two items (number 3 and 5) have been pulled/moved.
        // The total number of changes should equal 4.
        XCTAssertEqual(4, changes.allChanges.count)
        XCTAssertEqual(2, changes.removed.count)
        XCTAssertEqual(2, changes.moved.count)
    }

    func testMove_withPrimitives() {
        let old = [1, 2, 3, 4, 5]
        let new = [5, 1, 3, 2, 4]
        let changes = Diffuse.diff(old: old, new: new, comparator: { $0 == $1 })

        // The only item in its original position is the number 3. The rest have been moved.
        XCTAssertEqual(4, changes.allChanges.count)
        XCTAssertEqual(4, changes.moved.count)
    }

    // MARK: - Structs and custom comparator

    func testInsert_withCustomComparator() {
        let objects = createObjects()
        let old = objects
        var new = objects

        // Insert 2 new Objects. One at index 1, and one at the end.
        new.insert(Object(objId: 4, name: "E"), at: 1)
        new.append(Object(objId: 5, name: "F"))

        let changes = Diffuse.diff(old: old, new: new, comparator: { $0.objId == $1.objId })

        // `E` is inserted at index `1`, which means three items (`B`, `C` and `D`) have been pushed/moved.
        // The total number of changes should equal 5.
        XCTAssertEqual(5, changes.allChanges.count)
        XCTAssertEqual(2, changes.inserted.count)
        XCTAssertEqual(3, changes.moved.count)
    }

    func testRemove_withCustomComparator() {
        let objects = createObjects()
        let old = objects
        var new = objects

        // Remove two objects.
        new.remove(at: 1)
        new.remove(at: 1)

        let changes = Diffuse.diff(old: old, new: new, comparator: { $0.objId == $1.objId })

        // Two objects (`B` and `C`) are removed, which also means one item (`D`) have been pulled/moved.
        // The total number of changes should equal 3.
        XCTAssertEqual(3, changes.allChanges.count)
        XCTAssertEqual(2, changes.removed.count)
        XCTAssertEqual(1, changes.moved.count)
    }

    func testUpdate_withCustomComparator() {
        let objects = createObjects()
        let old = objects
        var new = objects

        // Update two objects.
        new[1].name = "New name"
        new[3].name = "New name"

        let changes = Diffuse.diff(old: old, new: new, comparator: { $0.objId == $1.objId })

        XCTAssertEqual(2, changes.updated.count)
        XCTAssertEqual(2, changes.allChanges.count)
    }

    func testMultipleOperations_withCustomComparator() {
        let objectA = Object(objId: 0, name: "A")
        var objectB = Object(objId: 1, name: "B")
        let objectC = Object(objId: 2, name: "C")
        let objectD = Object(objId: 3, name: "D")
        let objectE = Object(objId: 4, name: "E")
        let objectF = Object(objId: 5, name: "F")
        let old = [objectA, objectB, objectC]

        // Remove `ObjectA`
        //      = 1 change (remove + pull/move `B` to index 0)
        // Update `B`
        //      = 1 change
        // Insert `D` and `E` before `C`
        //      = 3 changes (2 inserts + push/move `C`)
        // Insert `F` after `C`
        //      = 1 change
        objectB.name = "New name"

        let new = [objectB, objectD, objectE, objectC, objectF]
        let changes = Diffuse.diff(old: old, new: new, comparator: { $0.objId == $1.objId })

        XCTAssertEqual(7, changes.allChanges.count)
        XCTAssertEqual(3, changes.inserted.count)
        XCTAssertEqual(1, changes.removed.count)
        XCTAssertEqual(2, changes.moved.count)
        XCTAssertEqual(1, changes.updated.count)
    }

    // MARK: - Helpers

    private func createObjects() -> [Object] {
        let names = ["A", "B", "C", "D"]
        return names.enumerated().map { Object(objId: $0.offset, name: $0.element)}
    }
}
