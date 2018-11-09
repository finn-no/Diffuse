//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import Foundation

public enum Change {
    case insert(row: Int)
    case remove(row: Int)
    case move(fromRow: Int, toRow: Int)
    case updated(row: Int)
}
