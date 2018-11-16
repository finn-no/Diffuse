//
//  Created by Granheim Brustad , Henrik on 16/11/2018.
//

import XCTest
@testable import Diffuse

final class ElementTests: XCTestCase {
    private let elementA = Element(value: 1, index: 0)
    private let elementB = Element(value: 1, index: 1)
    private let elementC = Element(value: 2, index: 0)

    func testHashValue() {
        XCTAssertEqual(elementA.hashValue, elementB.hashValue)
        XCTAssertNotEqual(elementA.hashValue, elementC.hashValue)
    }

    func testEquatable() {
        XCTAssertEqual(elementA, elementB)
        XCTAssertNotEqual(elementA, elementC)
    }
}
