//
//  ItemJournal.swift
//  AnyTracker
//
//  Created by Cristian Sava on 07/10/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import Foundation

class ItemJournal: Item, ItemTypeJournal {
    var version: String = App.version
    
    var name: String = ""
    var ID: String = ""
    var description: String = ""
    fileprivate(set) var type: ItemType = ItemType.Journal
    var useDate: Bool = false
    var startDate: Date
    var endDate: Date
    
    fileprivate(set) var entries: [Entry] = []
    
    required init() {
        self.startDate = Date()
        self.endDate = self.startDate
    }
    
    convenience init(withName name: String, ID: String, description: String, useDate: Bool, startDate: Date, endDate: Date, sum: Double = 0, entries: [Entry] = []) {
        self.init()
        initItem(withName: name, ID: ID, description: description, useDate: useDate, startDate: startDate, endDate: endDate)
        
        self.entries = entries
    }
    
    func isEmpty() -> Bool {
        return entries.count == 0
    }
    
    func toString() -> String? {
        return toJSONString()
    }
    
    func insert(entry: Entry) throws {
        entries.insert(entry, at: 0)
        
        do {
            try saveToFile()
        } catch {
            entries.removeFirst()
            if let statusError = error as? Status {
                throw statusError
            }
            throw Status.ErrorDefault
        }
        
        Utils.debugLog("Successfully added entry to Journal item \(ID)")
    }
    
    func remove(atIndex index: Int) throws {
        if index < 0 || index >= entries.count {
            throw Status.ErrorIndex
        }
        
        let deleted = Entry(name: entries[index].name, value: entries[index].value)
        entries.remove(at: index)
        
        do {
            try saveToFile()
        } catch {
            entries.append(deleted)
            if let statusError = error as? Status {
                throw statusError
            }
            throw Status.ErrorDefault
        }
        
        Utils.debugLog("Successfully removed entry from Journal item \(ID)")
    }
    
    func updateEntry(atIndex index: Int, newName name: String, newValue value: Date) throws {
        if index < 0 || index >= entries.count {
            throw Status.ErrorIndex
        }
        
        if entries[index].name == name && entries[index].value == value {
            return
        }
        
        let old = Entry(name: entries[index].name, value: entries[index].value)
        let new = Entry(name: name, value: value)
        entries[index] = new
        
        do {
            try saveToFile()
        } catch {
            entries[index] = old
            if let statusError = error as? Status {
                throw statusError
            }
            throw Status.ErrorDefault
        }
        
        Utils.debugLog("Successfully updated entry of Journal item \(ID)")
    }
    
    // MARK: -
}

extension ItemJournal: JSON {
    // MARK: JSON Protocol
    
    func toJSONString() -> String? {
        var dict: JSONDictionary = getItemAsJSONDictionary()
        
        var arrayEntries: JSONArray = []
        for entry in entries {
            var dictEntry: JSONDictionary = [:]
            dictEntry["name"] = entry.name as JSONObject?
            dictEntry["value"] = Utils.timeFromDate(entry.value) as JSONObject?
            
            arrayEntries.append(dictEntry as JSONObject)
        }
        dict["entries"] = arrayEntries as JSONObject?
        
        let jsonString = Utils.getJSONFromObject(dict as JSONObject?)
        Utils.debugLog("Serialized journal item to JSON string \(jsonString)")
        
        return jsonString
    }
    
    static func fromJSONString(_ input: String?) -> ItemJournal? {
        guard let (dict, version, name, ID, description, type, useDate, startDate, endDate) = getItemFromJSONDictionary(input) else {
            return nil
        }
        
        Utils.debugLog(input!)
        if type != ItemType.Journal.rawValue {
            Utils.debugLog("Item is not of type journal")
            return nil
        }
        
        guard let entriesArray = dict["entries"] as? [AnyObject] else {
            Utils.debugLog("Item entries are invalid")
            return nil
        }
        var entries: [Entry] = []
        for entryObject in entriesArray {
            if let name = entryObject["name"] as? String, let value = Utils.dateFromTime(entryObject["value"] as? String) {
                let entry = Entry(name: name, value: value)
                entries.append(entry)
                Utils.debugLog(entry.name + " " + Utils.stringFrom(date: entry.value, longFormat: false))
            }
        }
        
        let itemJournal = ItemJournal(withName: name, ID: ID, description: description, useDate: useDate, startDate: startDate, endDate: endDate, entries: entries)
        if !itemJournal.setVersion(version) {
            return nil
        }
        
        return itemJournal
    }
}