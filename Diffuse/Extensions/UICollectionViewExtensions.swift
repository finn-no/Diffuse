//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import UIKit

extension UICollectionView {
    public func reload(with changes: CollectionChanges,
                       section: Int = 0,
                       updateDataSource: () -> Void) {
        guard changes.count != 0 else { return }
        let indexPaths = IndexPathResult(changes: changes, section: section)

        performBatchUpdates({
            updateDataSource()
            insertItems(at: indexPaths.inserted)
            reloadItems(at: indexPaths.updated)
            deleteItems(at: indexPaths.removed)
            indexPaths.moved.forEach { (fromRow, toRow) in
                moveItem(at: fromRow, to: toRow)
            }
        })
    }
}
