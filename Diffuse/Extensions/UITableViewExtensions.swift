//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import UIKit

extension UITableView {
    public func reload(with changes: CollectionChanges,
                       section: Int = 0,
                       updateDataSource: () -> Void) {
        guard changes.count != 0 else { return }
        let indexPaths = IndexPathResult(changes: changes, section: section)
        let animation = UITableView.RowAnimation.automatic

        if #available(iOS 11, *) {
            performBatchUpdates({
                updateDataSource()
                insertRows(at: indexPaths.inserted, with: animation)
                reloadRows(at: indexPaths.updated, with: animation)
                deleteRows(at: indexPaths.removed, with: animation)
                indexPaths.moved.forEach { (fromRow, toRow) in
                    moveRow(at: fromRow, to: toRow)
                }
            })
        } else {
            beginUpdates()
            updateDataSource()
            insertRows(at: indexPaths.inserted, with: animation)
            reloadRows(at: indexPaths.updated, with: animation)
            deleteRows(at: indexPaths.removed, with: animation)
            indexPaths.moved.forEach { (fromRow, toRow) in
                moveRow(at: fromRow, to: toRow)
            }
            endUpdates()
        }
    }
}
