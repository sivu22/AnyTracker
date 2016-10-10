//
//  Protocols.swift
//  AnyTracker
//
//  Created by Cristian Sava on 10/07/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import Foundation
import UIKit

protocol NameAndID {
    var name: String { get }
    var ID: String { get }
}

// Always consider the current app version when handling data
protocol Version: class {
    var version: String { get set }
    
    func setVersion(_ newVersion: String) -> Bool
    func compareWithVersion(_ cmpVersion: String) -> Int
}

extension Version {
    func setVersion(_ newVersion: String) -> Bool {
        if newVersion < version {
            return false
        }
        
        version = newVersion
        return true
    }
    
    func compareWithVersion(_ cmpVersion: String) -> Int {
        if version < cmpVersion {
            return -1
        } else if version > cmpVersion {
            return 1
        }
        
        return 0
    }
}

protocol JSON {
    associatedtype ObjectType
    
    func toJSONString() -> String?
    static func fromJSONString(_ input: String?) -> ObjectType?
}

protocol CellKeyboardEvent {
    func willBeginEditing(fromView view: UIView)
    func willEndEditing(fromView view: UIView)
}
