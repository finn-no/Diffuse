//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//
struct Element<T: Hashable>: Hashable {
    let value: T
    let index: Int

    var hashValue: Int {
        return value.hashValue
    }

    static func == (lhs: Element<T>, rhs: Element<T>) -> Bool {
        return lhs.value == rhs.value
    }
}
