//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import Foundation

public struct CollectionChanges {
    public let inserted: [Change]
    public let removed: [Change]
    public let moved: [Change]
    public let updated: [Change]

    public var allChanges: [Change] {
        return inserted + removed + moved + updated
    }

    public init(inserted: [Change] = [], removed: [Change] = [], moved: [Change] = [], updated: [Change] = []) {
        self.inserted = inserted
        self.removed = removed
        self.moved = moved
        self.updated = updated
    }
}
