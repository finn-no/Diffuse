//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import XCTest
@testable import Diffuse

class CollectionChangesTests: XCTestCase {
    func testFiltering() {
        let changes: [Change] = [
            .insert(row: 0),
            .remove(row: 0), .remove(row: 0),
            .move(fromRow: 0, toRow: 0), .move(fromRow: 0, toRow: 0), .move(fromRow: 0, toRow: 0),
            .updated(row: 0), .updated(row: 0), .updated(row: 0), .updated(row: 0)]

        let collectionChanges = CollectionChanges(allChanges: changes)

        XCTAssertEqual(10, collectionChanges.allChanges.count)

        XCTAssertEqual(1, collectionChanges.inserted.count)
        XCTAssertEqual(2, collectionChanges.removed.count)
        XCTAssertEqual(3, collectionChanges.moved.count)
        XCTAssertEqual(4, collectionChanges.updated.count)
    }
}
