//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import XCTest
@testable import Diffuse

class CollectionChangesTests: XCTestCase {
    func testFiltering() {
        let changes: [Change] = [
            .insert(at: 0),
            .remove(from: 0), .remove(from: 0),
            .move(from: 0, to: 0), .move(from: 0, to: 0), .move(from: 0, to: 0),
            .updated(at: 0), .updated(at: 0), .updated(at: 0), .updated(at: 0)]

        let collectionChanges = CollectionChanges(allChanges: changes)

        XCTAssertEqual(10, collectionChanges.allChanges.count)

        XCTAssertEqual(1, collectionChanges.inserted.count)
        XCTAssertEqual(2, collectionChanges.removed.count)
        XCTAssertEqual(3, collectionChanges.moved.count)
        XCTAssertEqual(4, collectionChanges.updated.count)
    }
}
