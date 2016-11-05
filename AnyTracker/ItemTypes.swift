//
//  ItemTypes.swift
//  AnyTracker
//
//  Created by Cristian Sava on 19/08/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import Foundation

enum ItemType: String {
    case Sum = "Sum", Counter = "Counter", Journal = "Journal"
    
    // Maximum 10 types of items!
    func getTypeIndex() -> Int {
        switch self {
        case .Sum:
            return 0
        case .Counter:
            return 1
        case .Journal:
            return 2
        }
    }
    
    static func getType(fromIndex index: Character) -> ItemType? {
        switch index {
        case "0":
            return Sum
        case "1":
            return Counter
        case "2":
            return Journal
        default:
            return nil
        }
    }
    
    static func numberOfItems() -> Int {
        return 3
    }
}

// MARK: - Sum

struct Element {
    let name: String
    let value: Double
}

protocol ItemTypeSum {
    var sum: Double { get }
    var elements: [Element] { get }
}

// MARK: - Counter

protocol ItemTypeCounter {
    var counter: UInt { get }
}

// MARK: - Journal

struct Entry {
    let name: String
    let value: Date
}

protocol ItemTypeJournal {
    var entries: [Entry] { get }
}

