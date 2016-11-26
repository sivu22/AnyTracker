//
//  Item.swift
//  AnyTracker
//
//  Created by Cristian Sava on 10/07/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import Foundation

protocol ItemInit {
    init()
    // Convenience in disguise
    func initItem(withName name: String, ID: String, description: String, useDate: Bool, startDate: Date, endDate: Date)
}

protocol ItemJSON {
    func getItemAsJSONDictionary() -> JSONDictionary
    static func getItemFromJSONDictionary(_ input: String?) -> (JSONDictionary, String, String, String, String, String, Bool, Date, Date)?
}

protocol ItemChangeDelegate {
    func itemChanged()
}

protocol NotifyItemUpdate {
    var itemChangeDelegate: ItemChangeDelegate? { get set }
}

protocol Item: class, Version, NameAndID, ItemInit, ItemJSON {
    var name: String { get set }
    var ID: String { get set }
    
    var description: String { get set }
    var type: ItemType { get }
    var useDate: Bool { get set }
    var startDate: Date { get set }
    var endDate: Date { get set }
    
    func isEmpty() -> Bool
    func toString() -> String?
    
    func saveToFile() throws
    // true if item changed at all, false if item is the same as before
    func updateWith(newName name: String, newDescription description: String, newUseDate useDate: Bool, newStartDate startDate: Date, newEndDate endDate: Date) throws -> Bool
}

// MARK: - Item common init

extension Item {
    func initItem(withName name: String, ID: String, description: String, useDate: Bool, startDate: Date, endDate: Date) {
        self.name = name
        self.ID = ID
        
        self.description = description
        self.useDate = useDate
        self.startDate = startDate
        self.endDate = endDate
    }
}

// MARK: - Item common JSON functions 

extension Item {
    func getItemAsJSONDictionary() -> JSONDictionary {
        var dict: JSONDictionary = [:]
        dict["version"] = version as JSONObject?
        dict["name"] = name as JSONObject?
        dict["ID"] = ID as JSONObject?
        dict["description"] = description as JSONObject?
        dict["type"] = type.rawValue as JSONObject?
        dict["useDate"] = useDate as JSONObject?
        dict["startDate"] = Utils.timeFromDate(startDate) as JSONObject?
        dict["endDate"] = Utils.timeFromDate(endDate) as JSONObject?
        
        return dict
    }
    
    static func getItemFromJSONDictionary(_ input: String?) -> (JSONDictionary, String, String, String, String, String, Bool, Date, Date)? {
        let dict = Utils.getDictionaryFromJSON(input)
        guard dict != nil else {
            return nil
        }
        
        guard let version = dict!["version"] as? String else {
            Utils.debugLog("Item version invalid")
            return nil
        }
        guard let name = dict!["name"] as? String else {
            Utils.debugLog("Item name invalid")
            return nil
        }
        guard let ID = dict!["ID"] as? String else {
            Utils.debugLog("Item ID invalid")
            return nil
        }
        guard let description = dict!["description"] as? String else {
            Utils.debugLog("Item description invalid")
            return nil
        }
        guard let type = dict!["type"] as? ItemType.RawValue else {
            Utils.debugLog("Item type invalid")
            return nil
        }
        guard let useDate = dict!["useDate"] as? Bool else {
            Utils.debugLog("Item using date invalid")
            return nil
        }
        guard let startDate = Utils.dateFromTime(dict!["startDate"] as? String) else {
            Utils.debugLog("Item start date invalid")
            return nil
        }
        guard let endDate = Utils.dateFromTime(dict!["endDate"] as? String) else {
            Utils.debugLog("Item end date invalid")
            return nil
        }
        
        return (dict!, version, name, ID, description, type, useDate, startDate, endDate)
    }
}

// MARK: - Item general purpose functions

extension Item {
    func saveToFile() throws {
        guard let JSONString = toString() else {
            Utils.debugLog("Failed to serialize JSON item")
            throw Status.errorJSONSerialize
        }
        
        if !Utils.createFile(withName: ID, withContent: JSONString, overwriteExisting: true) {
            Utils.debugLog("Failed to save item to file")
            throw Status.errorItemFileSave
        }
    }
    
    func updateWith(newName name: String, newDescription description: String, newUseDate useDate: Bool, newStartDate startDate: Date, newEndDate endDate: Date) throws -> Bool {
        let changed = self.name != name || self.description != description || self.useDate != useDate || self.startDate != startDate || self.endDate != endDate
        
        if changed {
            Utils.debugLog("Item changed, will try to update ...")
            
            self.name = name
            self.description = description
            self.useDate = useDate
            self.startDate = startDate
            self.endDate = endDate
            
            do {
                try saveToFile()
            } catch {
                throw error
            }
        }
        
        return changed
    }
}
