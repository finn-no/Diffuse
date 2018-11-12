//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import Foundation

struct Item<T: Hashable>: Hashable, Equatable {
    let value: T
    let offset: Int
    let isNew: Bool

    var hashValue: Int {
        return value.hashValue ^ offset
    }

    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.value == rhs.value && lhs.offset == rhs.offset
    }
}
