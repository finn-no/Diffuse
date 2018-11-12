//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import UIKit

extension UITableView {
    public func reload(with changes: CollectionChanges,
                       insertAnimation: UITableView.RowAnimation = .automatic,
                       reloadAnimation: UITableView.RowAnimation = .automatic,
                       deleteAnimation: UITableView.RowAnimation = .automatic,
                       section: Int = 0,
                       updateDataSource: () -> Void) {
        guard changes.allChanges.count != 0 else { return }
        let indexPaths = IndexPathResult(changes: changes, section: section)

        if #available(iOS 11, *) {
            performBatchUpdates({
                updateDataSource()
                insertRows(at: indexPaths.inserted, with: insertAnimation)
                reloadRows(at: indexPaths.updated, with: reloadAnimation)
                deleteRows(at: indexPaths.removed, with: deleteAnimation)
                indexPaths.moved.forEach { (fromRow, toRow) in
                    moveRow(at: fromRow, to: toRow)
                }
            })
        } else {
            beginUpdates()
            updateDataSource()
            insertRows(at: indexPaths.inserted, with: insertAnimation)
            reloadRows(at: indexPaths.updated, with: reloadAnimation)
            deleteRows(at: indexPaths.removed, with: deleteAnimation)
            indexPaths.moved.forEach { (fromRow, toRow) in
                moveRow(at: fromRow, to: toRow)
            }
            endUpdates()
        }
    }
}
