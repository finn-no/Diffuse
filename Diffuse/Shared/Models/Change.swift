//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import Foundation

public enum Change {
    case insert(at: Int)
    case remove(from: Int)
    case move(from: Int, to: Int)
    case updated(at: Int)
}
