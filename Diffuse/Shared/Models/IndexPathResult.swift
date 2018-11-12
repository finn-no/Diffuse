//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import Foundation

struct IndexPathResult {
    private let section: Int
    private let changes: CollectionChanges

    public var inserted: [IndexPath] {
        return changes.inserted.map { change -> IndexPath? in
            guard case let .insert(row: row) = change else { return nil }
            return IndexPath(row: row, section: section)
        }.compactMap { $0 }
    }

    public var removed: [IndexPath] {
        return changes.removed.map { change -> IndexPath? in
            guard case let .remove(row: row) = change else { return nil }
            return IndexPath(row: row, section: section)
        }.compactMap { $0 }
    }

    public var moved: [(from: IndexPath, to: IndexPath)] {
        return changes.updated.map { change -> (from: IndexPath, to: IndexPath)? in
            guard case let .move(fromRow: fromRow, toRow: toRow) = change else { return nil }
            return (from: IndexPath(row: fromRow, section: section), to: IndexPath(row: toRow, section: section))
        }.compactMap { $0 }
    }

    public var updated: [IndexPath] {
        return changes.updated.map { change -> IndexPath? in
            guard case let .updated(row: row) = change else { return nil }
            return IndexPath(row: row, section: section)
        }.compactMap { $0 }
    }

    init(changes: CollectionChanges, section: Int) {
        self.changes = changes
        self.section = section
    }
}
