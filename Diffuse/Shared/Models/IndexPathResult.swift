//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import Foundation

struct IndexPathResult {
    private let section: Int
    private let changes: CollectionChanges

    public var inserted: [IndexPath] {
        return changes.inserted.map { IndexPath(item: $0, section: section) }
    }

    public var removed: [IndexPath] {
        return changes.removed.map { IndexPath(item: $0, section: section) }
    }

    public var moved: [Move<IndexPath>] {
        return changes.moved.map { move in
            let from = IndexPath(item: move.from, section: section)
            let to = IndexPath(item: move.to, section: section)
            return Move(from: from, to: to)
        }
    }

    public var updated: [IndexPath] {
        return changes.updated.map { IndexPath(item: $0, section: section) }
    }

    init(changes: CollectionChanges, section: Int) {
        self.changes = changes
        self.section = section
    }
}
