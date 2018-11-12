//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import UIKit

public enum TableViewOperation {
    case insert
    case reload
    case delete
}

extension UITableView {
    public func reload(with changes: CollectionChanges,
                       animations: [TableViewOperation: UITableView.RowAnimation]?,
                       section: Int = 0,
                       updateDataSource: () -> Void) {
        guard changes.allChanges.count != 0 else { return }
        let indexPaths = IndexPathResult(changes: changes, section: section)

        let insertAnimation = animations?[.insert] ?? .automatic
        let reloadAnimation = animations?[.reload] ?? .automatic
        let deleteAnimation = animations?[.delete] ?? .automatic

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
