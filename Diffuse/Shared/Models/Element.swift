//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

struct Element<T: Hashable>: Hashable {
    let value: T
    let index: Int

    func hash(into hasher: inout Hasher) {
        hasher.combine(value.hashValue)
    }

    static func == (lhs: Element<T>, rhs: Element<T>) -> Bool {
        return lhs.value == rhs.value
    }
}
