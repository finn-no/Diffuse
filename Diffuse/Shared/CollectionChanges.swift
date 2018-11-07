//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import Foundation

public struct CollectionChanges {
    private(set) var allChanges: [Change]

    var inserted: [Change] {
        return allChanges.filter { change in
            switch change {
            case .insert(at: _): return true
            default: return false
            }
        }
    }

    var removed: [Change] {
        return allChanges.filter { change in
            switch change {
            case .remove(from: _): return true
            default: return false
            }
        }
    }

    var moved: [Change] {
        return allChanges.filter { change in
            switch change {
            case .move(from: _, to: _): return true
            default: return false
            }
        }
    }

    var updated: [Change] {
        return allChanges.filter { change in
            switch change {
            case .updated(at: _): return true
            default: return false
            }
        }
    }
}
