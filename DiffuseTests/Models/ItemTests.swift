//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import XCTest
@testable import Diffuse

final class ItemTests: XCTestCase {
    private let itemA = Item(value: 1, offset: 0, isNew: true)
    private let itemB = Item(value: 1, offset: 0, isNew: true)
    private let itemC = Item(value: 1, offset: 0, isNew: false)
    private let itemD = Item(value: 1, offset: 1, isNew: true)

    func testHashValue() {
        XCTAssertEqual(itemA.hashValue, itemB.hashValue)
        XCTAssertEqual(itemA.hashValue, itemC.hashValue)
        XCTAssertNotEqual(itemA.hashValue, itemD.hashValue)
    }

    func testEquatable() {
        XCTAssertEqual(itemA, itemB)
        XCTAssertEqual(itemA, itemC)
        XCTAssertNotEqual(itemA, itemD)
    }
}
