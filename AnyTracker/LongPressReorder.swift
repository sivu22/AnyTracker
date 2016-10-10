//
//  LongPressReorder.swift
//  AnyTracker
//
//  Created by Cristian Sava on 07/08/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import UIKit

protocol LongPressReorder {
    func changedAction()
    func defaultAction()
    
    func beganGuard(withIndex indexPath: IndexPath) -> Bool
    func changedGuard(withIndex indexPath: IndexPath) -> Bool
}

extension UITableViewController: LongPressReorder {
    // Override it
    func changedAction() {
    }
    
    // Override it
    func defaultAction() {
    }
    
    // Override it or not
    func beganGuard(withIndex indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Override it or not
    func changedGuard(withIndex indexPath: IndexPath) -> Bool {
        return true
    }
    
    func addLongPressGesture() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressGestureRecognized(_:)))
        tableView.addGestureRecognizer(longPress)
    }
    
    struct DragInfo {
        static var began: Bool = false
        static var cellSnapshot: UIView!
        static var sourceIndexPath: IndexPath!
        static var destinationIndexPath: IndexPath!
        static var cellAnimating: Bool = false
        static var cellMustShow : Bool = false
    }
    
    func longPressGestureRecognized(_ gesture: UIGestureRecognizer) {
        let point = gesture.location(in: tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        DragInfo.destinationIndexPath = indexPath
        
        switch gesture.state {
        case .began:
            if let indexPath = indexPath {
                if !beganGuard(withIndex: indexPath) {
                    break
                }
                DragInfo.began = true
                
                let cell = tableView.cellForRow(at: indexPath)!
                DragInfo.sourceIndexPath = indexPath
                
                var center = cell.center
                DragInfo.cellSnapshot = Utils.snapshotFromView(cell)
                DragInfo.cellSnapshot.center = center
                DragInfo.cellSnapshot.alpha = 0
                
                tableView.addSubview(DragInfo.cellSnapshot)
                
                UIView.animate(withDuration: 0.25, animations: {
                    center.y = point.y
                    DragInfo.cellAnimating = true
                    DragInfo.cellSnapshot.center = center
                    DragInfo.cellSnapshot.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
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
            if !changedGuard(withIndex: indexPath) {
                break
            }
            
            var center = DragInfo.cellSnapshot.center
            center.y = point.y
            DragInfo.cellSnapshot.center = center
            
            if indexPath != DragInfo.sourceIndexPath {
                changedAction()
                
                tableView.moveRow(at: DragInfo.sourceIndexPath, to: indexPath)
                DragInfo.sourceIndexPath = indexPath
            }
            
        default:
            guard DragInfo.began else {
                break
            }
            DragInfo.began = false
            
            if let cell = tableView.cellForRow(at: DragInfo.sourceIndexPath) {
                if !DragInfo.cellAnimating {
                    cell.isHidden = false
                    cell.alpha = 0
                } else {
                    DragInfo.cellMustShow = true
                }
                
                UIView.animate(withDuration: 0.25, animations: {
                    DragInfo.cellSnapshot.center = cell.center
                    DragInfo.cellSnapshot.transform = CGAffineTransform.identity
                    DragInfo.cellSnapshot.alpha = 0
                    cell.alpha = 1
                    }, completion: { (_) in
                        DragInfo.cellSnapshot.removeFromSuperview()
                        DragInfo.cellSnapshot = nil
                        DragInfo.sourceIndexPath = nil
                })
                
                defaultAction()
            }
            
        }
    }
}
