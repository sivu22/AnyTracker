//
//  Items.swift
//  AnyTracker
//
//  Created by Cristian Sava on 07/08/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import Foundation

protocol ItemOps {
    static func createItem(withName name: String, description: String, type: ItemType, useDate: Bool, startDate: Date, endDate: Date) throws -> Item
    
    static func loadItem(withID ID:String) throws -> Item
    
    static func deleteItemFile(withID ID: String) -> Bool
    
    static func getItemType(fromID ID: String) -> ItemType?
}

extension ItemOps {
    static fileprivate func createItemID(withType type: ItemType) throws -> String {
        let typeIndex = type.getTypeIndex()
        var i = 0
        var fileName: String = ""
        let currentTime = Utils.currentTime()
        while i < 10 {
            fileName = Constants.File.item + String(typeIndex) + String(i) + currentTime + Constants.File.ext;
            if !Utils.fileExists(atPath: fileName) {
                break
            }
            
            i += 1
        }
        
        if i == 10 {
            throw Status.errorItemBadID
        }
        
        return fileName
    }
    
    static func createItem(withName name: String, description: String, type: ItemType, useDate: Bool, startDate: Date, endDate: Date) throws -> Item {
        var ID: String
        do {
            ID = try Self.createItemID(withType: type)
        } catch let error {
            throw error
        }
        
        var item: Item
        switch type {
        case .sum:
            item = ItemSum(withName: name, ID: ID, description: description, useDate: useDate, startDate: startDate, endDate: endDate)
        case .counter:
            item = ItemCounter(withName: name, ID: ID, description: description, useDate: useDate, startDate: startDate, endDate: endDate)
        case .journal:
            item = ItemJournal(withName: name, ID: ID, description: description, useDate: useDate, startDate: startDate, endDate: endDate)
        }
        
        return item
    }
    
    static fileprivate func loadItem(ofType type: ItemType, withContent content: String) -> Item? {
        switch(type) {
        case .sum:
            return ItemSum.fromJSONString(content)
        case .counter:
            return ItemCounter.fromJSONString(content)
        case .journal:
            return ItemJournal.fromJSONString(content)
        }
    }
    
    static func loadItem(withID fileName:String) throws -> Item {
        guard Utils.validString(fileName) && fileName.count > 5 else {
            Utils.debugLog("Bad filename for item")
            throw Status.errorInputString
        }
        
        guard let content = Utils.readFile(withName: fileName) else {
            Utils.debugLog("Failed to load item from file")
            throw Status.errorListFileLoad
        }
        
        guard let type = ItemType.getType(fromIndex: fileName[fileName.index(fileName.startIndex, offsetBy: 4)]) else {
            Utils.debugLog("Failed to get item type")
            throw Status.errorListFileLoad
        }
        
        guard let item = loadItem(ofType: type, withContent: content) else {
            Utils.debugLog("Failed to deserialize JSON item")
            throw Status.errorJSONDeserialize
        }
        
        return item
    }
    
    static func deleteItemFile(withID ID: String) -> Bool {
        let filePath = Utils.documentsPath + "/" + ID
        if !Utils.deleteFile(atPath: filePath) {
            Utils.debugLog("Failed to delete item \(ID)")
            return false
        }
        
        Utils.debugLog("Successfully deleted item \(ID)")
        return true
    }
    
    static func getItemType(fromID ID: String) -> ItemType? {
        let type = ItemType.getType(fromIndex: ID[ID.index(ID.startIndex, offsetBy: 4)])
        
        return type
    }
}


struct Items: ItemOps {
}
