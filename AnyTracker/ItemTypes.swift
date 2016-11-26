//
//  ItemTypes.swift
//  AnyTracker
//
//  Created by Cristian Sava on 19/08/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import Foundation

enum ItemType: String {
    case sum = "Sum", counter = "Counter", journal = "Journal"
    
    // Maximum 10 types of items!
    func getTypeIndex() -> Int {
        switch self {
        case .sum:
            return 0
        case .counter:
            return 1
        case .journal:
            return 2
        }
    }
    
    static func getType(fromIndex index: Character) -> ItemType? {
        switch index {
        case "0":
            return sum
        case "1":
            return counter
        case "2":
            return journal
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

