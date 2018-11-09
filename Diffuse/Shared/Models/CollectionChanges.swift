//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import Foundation

public struct CollectionChanges {
    public private(set) var allChanges: [Change]

    public var inserted: [Change] {
        return allChanges.filter { change in
            switch change {
            case .insert(row: _): return true
            default: return false
            }
        }
    }

    public var removed: [Change] {
        return allChanges.filter { change in
            switch change {
            case .remove(row: _): return true
            default: return false
            }
        }
    }

    public var moved: [Change] {
        return allChanges.filter { change in
            switch change {
            case .move(fromRow: _, toRow: _): return true
            default: return false
            }
        }
    }

    public var updated: [Change] {
        return allChanges.filter { change in
            switch change {
            case .updated(row: _): return true
            default: return false
            }
        }
    }
}
