//
//  LongPressReorder.swift
//  AnyTracker
//
//  Created by Cristian Sava on 07/08/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import UIKit

enum SelectedRowScale: CGFloat {
    case small = 1.01
    case medium = 1.03
    case big = 1.05
}

/**
 Notifications that allow configuring the reorder of rows.
*/
protocol LongPressReorder {
    
    /**
     Will be called when the moving row changes its current position to a new position inside the table
     
     - Parameter currentIndex: Current position of row inside the table
     - Parameter newIndex: New position of row inside the table
     */
    func positionChanged(currentIndex: IndexPath, newIndex: IndexPath)
    /**
     Will be called when reordering is done (long press gesture finishes)
     
     - Parameter initialIndex: Initial position of row inside the table, when the long press gesture starts
     - Parameter finalIndex: Final position of row inside the table, when the long press gesture finishes
     */
    func reorderFinished(initialIndex: IndexPath, finalIndex: IndexPath)
    
    /**
     Specify if the current selected row should be reordered via drag and drop
     
     - Parameter atIndex: Position of row
     - Returns: True to allow selected row to be reordered, false if row should not be moved
     */
    func startReorderingRow(atIndex indexPath: IndexPath) -> Bool
    /**
     Specify if the targeted row can change its position
     
     - Parameter atIndex: Position of row that is allowed to be swapped
     - Returns: True to allow row to change its position, false if row is imutable
     */
    func allowChangingRow(atIndex indexPath: IndexPath) -> Bool
}

// MARK: - UITableView wrapper for supporting drag and drop reorder

class LongPressReorderTableView {
    
    /// The table which will support reordering of rows
    fileprivate(set) var tableView: UITableView
    /// Optional delegate for overriding default behaviour. Normally a subclass of UI(Table)ViewController.
    var delegate: LongPressReorder?
    /// Controls how much the selected row will "pop out" of the table
    var selectedRowScale: SelectedRowScale
    
    /// Helper struct used to track parameters involved in drag and drop of table row
    fileprivate struct DragInfo {
        static var began: Bool = false
        static var cellSnapshot: UIView!
        static var initialIndexPath: IndexPath!
        static var currentIndexPath: IndexPath!
        static var cellAnimating: Bool = false
        static var cellMustShow : Bool = false
    }
    
    /**
     Single designated initializer
     
     - Parameter tableView: Targeted UITableView
     */
    init(_ tableView: UITableView, selectedRowScale: SelectedRowScale = .medium) {
        self.tableView = tableView
        self.selectedRowScale = selectedRowScale
    }
    
    // MARK: - Exposed actions
    
    /**
     Add a long press gesture recognizer to the table view, therefore enabling row reordering via drag and drop
     */
    func enableLongPressReorder() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressGestureRecognized(_:)))
        tableView.addGestureRecognizer(longPress)
    }
    
    // MARK: - Long press gesture action
    
    @objc fileprivate func longPressGestureRecognized(_ gesture: UIGestureRecognizer) {
        let point = gesture.location(in: tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        
        switch gesture.state {
        case .began:
            if let indexPath = indexPath {
                if !(delegate?.startReorderingRow(atIndex: indexPath) ?? true) {
                    break
                }
                DragInfo.began = true
                DragInfo.initialIndexPath = indexPath
                DragInfo.currentIndexPath = indexPath
                
                let cell = tableView.cellForRow(at: indexPath)!
                
                var center = cell.center
                DragInfo.cellSnapshot = Utils.snapshotFromView(cell)
                DragInfo.cellSnapshot.center = center
                DragInfo.cellSnapshot.alpha = 0
                
                tableView.addSubview(DragInfo.cellSnapshot)
                
                UIView.animate(withDuration: 0.25, animations: {
                    center.y = point.y
                    DragInfo.cellAnimating = true
                    DragInfo.cellSnapshot.center = center
                    DragInfo.cellSnapshot.transform = CGAffineTransform(scaleX: self.selectedRowScale.rawValue, y: self.selectedRowScale.rawValue)
                    DragInfo.cellSnapshot.alpha = 0.95
                    
                    cell.alpha = 0
                }, completion: { (finished) in
                    if finished {
                        DragInfo.cellAnimating = false
                        if DragInfo.cellMustShow {
                            DragInfo.cellMustShow = false
                            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                                cell.alpha = 1
                            })
                        } else {
                            cell.isHidden = true
                        }
                    }
                })
            }
            
        case .changed:
            guard DragInfo.began else {
                break
            }
            guard let indexPath = indexPath else {
                break
            }
            if !(delegate?.allowChangingRow(atIndex: indexPath) ?? true) {
                break
            }
            
            var center = DragInfo.cellSnapshot.center
            center.y = point.y
            DragInfo.cellSnapshot.center = center
            
            if indexPath != DragInfo.currentIndexPath {
                delegate?.positionChanged(currentIndex: DragInfo.currentIndexPath, newIndex: indexPath)
                
                tableView.moveRow(at: DragInfo.currentIndexPath, to: indexPath)
                DragInfo.currentIndexPath = indexPath
            }
            
        default:
            guard DragInfo.began else {
                break
            }
            DragInfo.began = false
            
            if let cell = tableView.cellForRow(at: DragInfo.currentIndexPath) {
                if !DragInfo.cellAnimating {
                    cell.isHidden = false
                    cell.alpha = 0
                } else {
                    DragInfo.cellMustShow = true
                }
                
                let currentIndexPath = DragInfo.currentIndexPath!
                let initialIndexPath = DragInfo.initialIndexPath!
                
                UIView.animate(withDuration: 0.25, animations: {
                    DragInfo.cellSnapshot.center = cell.center
                    DragInfo.cellSnapshot.transform = CGAffineTransform.identity
                    DragInfo.cellSnapshot.alpha = 0
                    cell.alpha = 1
                }, completion: { (_) in
                    DragInfo.cellSnapshot.removeFromSuperview()
                    DragInfo.cellSnapshot = nil
                    DragInfo.initialIndexPath = nil
                    DragInfo.currentIndexPath = nil
                })
                
                delegate?.reorderFinished(initialIndex: initialIndexPath, finalIndex: currentIndexPath)
            }
            
        }
    }
}

// MARK: - Default implementation of LongPressReorder notifications

extension UIViewController: LongPressReorder {
    
    /**
     Default implementation: does nothing.
     
     - Parameter currentIndex: Current position of row inside the table
     - Parameter newIndex: New position of row inside the table
     */
    func positionChanged(currentIndex: IndexPath, newIndex: IndexPath) {
    }
    
    /**
     Default implementation: does nothing.
     
     - Parameter initialIndex: Initial position of row inside the table, when the long press gesture starts
     - Parameter finalIndex: Final position of row inside the table, when the long press gesture finishes
     */
    func reorderFinished(initialIndex: IndexPath, finalIndex: IndexPath) {
    }
    
    /**
     Default implementation: every table row can be moved
     
     - Parameter atIndex: Position of row
     - Returns: True to allow selected row to be reordered, false if row should not be moved
     */
    func startReorderingRow(atIndex indexPath: IndexPath) -> Bool {
        return true
    }
    
    /**
     Default implementation: every table row can be swaped against the current moving row
     
     - Parameter atIndex: Position of row that is allowed to be swapped
     - Returns: True to allow row to change its position, false if row is imutable
     */
    func allowChangingRow(atIndex indexPath: IndexPath) -> Bool {
        return true
    }
}
