//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import Foundation

public struct CollectionChanges {
    public let inserted: [Int]
    public let removed: [Int]
    public let moved: [Move<Int>]
    public let updated: [Int]

    public var count: Int {
        return inserted.count + removed.count + moved.count + updated.count
    }

    public init(inserted: [Int] = [], removed: [Int] = [], moved: [Move<Int>] = [], updated: [Int] = []) {
        self.inserted = inserted
        self.removed = removed
        self.moved = moved
        self.updated = updated
    }
}
