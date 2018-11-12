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

    // MARK: - Primitives

    func testInsert_withPrimitives() {
        let old = [1, 2, 3]
        let new = [1, 4, 2, 3, 5]
        let changes = Diffuse.diff(old: old, new: new)

        // Number 4 is inserted at index `1`, which means two items (number 2 and 3) have been pushed/moved.
        // The total number of changes should equal 4.
        XCTAssertEqual(4, changes.allChanges.count)
        XCTAssertEqual(2, changes.inserted.count)
        XCTAssertEqual(2, changes.moved.count)
    }

    func testRemove_withPrimitives() {
        let old = [1, 2, 3, 4, 5]
        let new = [1, 3, 5]
        let changes = Diffuse.diff(old: old, new: new)

        // Two items are removed, but that also means two items (number 3 and 5) have been pulled/moved.
        // The total number of changes should equal 4.
        XCTAssertEqual(4, changes.allChanges.count)
        XCTAssertEqual(2, changes.removed.count)
        XCTAssertEqual(2, changes.moved.count)
    }

    func testMove_withPrimitives() {
        let old = [1, 2, 3, 4, 5]
        let new = [5, 1, 3, 2, 4]
        let changes = Diffuse.diff(old: old, new: new)

        // The only item in its original position is the number 3. The rest have been moved.
        XCTAssertEqual(4, changes.allChanges.count)
        XCTAssertEqual(4, changes.moved.count)
    }

    func testUpdate_withPrimitives() {
        let old = [1, 2, 3, 4, 5]
        let new = [1, 2, 3, 6, 5]
        let changes = Diffuse.diff(old: old, new: new)

        // The only item has been updated
        XCTAssertEqual(1, changes.allChanges.count)
        XCTAssertEqual(1, changes.updated.count)
    }

    // MARK: - Structs and custom comparator

    func testInsert_withCustomType() {
        let objects = createObjects()
        let old = objects
        var new = objects

        // Insert 2 new Objects. One at index 1, and one at the end.
        new.insert(Object(objId: 4, name: "E"), at: 1)
        new.append(Object(objId: 5, name: "F"))

        let changes = Diffuse.diff(old: old, new: new)

        // `E` is inserted at index `1`, which means three items (`B`, `C` and `D`) have been pushed/moved.
        // The total number of changes should equal 5.
        XCTAssertEqual(5, changes.allChanges.count)
        XCTAssertEqual(2, changes.inserted.count)
        XCTAssertEqual(3, changes.moved.count)
    }

    func testRemove_withCustomType() {
        let objects = createObjects()
        let old = objects
        var new = objects

        // Remove two objects.
        new.remove(at: 1)
        new.remove(at: 1)

        let changes = Diffuse.diff(old: old, new: new)

        // Two objects (`B` and `C`) are removed, which also means one item (`D`) have been pulled/moved.
        // The total number of changes should equal 3.
        XCTAssertEqual(3, changes.allChanges.count)
        XCTAssertEqual(2, changes.removed.count)
        XCTAssertEqual(1, changes.moved.count)
    }

    func testUpdate_withCustomType() {
        let objects = createObjects()
        let old = objects
        var new = objects

        // Update two objects.
        new[1].name = "New name"
        new[3].name = "New name"

        let changes = Diffuse.diff(old: old, new: new)

        XCTAssertEqual(2, changes.updated.count)
        XCTAssertEqual(2, changes.allChanges.count)
    }

    func testMultipleOperations_withCustomType() {
        let objectA = Object(objId: 0, name: "A")
        var objectB = Object(objId: 1, name: "B")
        let objectC = Object(objId: 2, name: "C")
        let objectD = Object(objId: 3, name: "D")
        let objectE = Object(objId: 4, name: "E")
        let objectF = Object(objId: 5, name: "F")
        let old = [objectA, objectB, objectC]

        // Move `C`
        //      = 1 change
        // Insert `E` and `F`
        //      = 2 changes
        // Update `A` to `B` and `B` to `D`
        //      = 2 change
        objectB.name = "New name"

        let new = [objectB, objectD, objectE, objectC, objectF]
        let changes = Diffuse.diff(old: old, new: new)

        XCTAssertEqual(5, changes.allChanges.count)
        XCTAssertEqual(1, changes.moved.count)
        XCTAssertEqual(2, changes.inserted.count)
        XCTAssertEqual(2, changes.updated.count)
    }

    // MARK: - Helpers

    private func createObjects() -> [Object] {
        let names = ["A", "B", "C", "D"]
        return names.enumerated().map { Object(objId: $0.offset, name: $0.element)}
    }
}
