//
//  List.swift
//  AnyTracker
//
//  Created by Cristian Sava on 09/03/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import Foundation

class List: Version, NameAndID {
    var version: String
    
    var name: String
    let ID: String
    fileprivate(set) var numItems: Int
    fileprivate(set) var items: [String]
    
    init(name: String, ID: String) {
        self.name = name
        self.ID = ID
        
        numItems = 0
        items = []
        version = App.version;
    }
    
    init(name: String, ID: String, numItems: Int, items: [String]) {
        self.name = name
        self.ID = ID
        self.numItems = numItems
        self.items = items
        version = App.version
    }
    
    static func createList(withName name: String) throws -> List {
        guard Utils.validString(name) else {
            Utils.debugLog("Bad list name provided")
            throw Status.ErrorInputString
        }
        
        var i = 0
        var fileName: String = ""
        let currentTime = Utils.currentTime()
        while i < 10 {
            fileName = App.Constants.File.list + String(i) + currentTime + App.Constants.File.ext;
            if !Utils.fileExists(atPath: fileName) {
                break
            }
            
            i += 1
        }
        
        if i == 10 {
            throw Status.ErrorListFileSave
        }
        
        let newList = List(name: name, ID: fileName)
        return newList
    }
    
    func updateList(withName newName: String) throws {
        name = newName
        
        do {
            try saveListToFile()
        } catch {
            Utils.debugLog("Failed to updateList with name \(newName)")
            throw error
        }
    }
    
    // MARK: - File operations
    
    func saveListToFile() throws {
        guard let JSONString = toJSONString() else {
            Utils.debugLog("Failed to serialize JSON list")
            throw Status.ErrorJSONSerialize
        }
        
        if !Utils.createFile(withName: ID, withContent: JSONString, overwriteExisting: true) {
            Utils.debugLog("Failed to save list to file")
            throw Status.ErrorListFileSave
        } else {
            Utils.debugLog("Saved list to file: \(JSONString)")
        }
    }
    
    static func loadListFromFile(_ fileName: String) throws -> List {
        guard Utils.validString(fileName) else {
            Utils.debugLog("Bad filename for list")
            throw Status.ErrorInputString
        }
        
        let content = Utils.readFile(withName: fileName)
        if content == nil {
            Utils.debugLog("Failed to load list from file")
            throw Status.ErrorListFileLoad
        }
        
        guard let list = fromJSONString(content) else {
            Utils.debugLog("Failed to deserialize JSON list")
            throw Status.ErrorJSONDeserialize
        }
        
        return list
    }
    
    // MARK: - Item operations
    
    func getItemIDs() -> [String] {
        return items
    }
    
    static func getItemIDs(fromList listName: String) -> [String] {
        var list: List?
        
        do {
            list = try List.loadListFromFile(listName)
        } catch {
            return [] as [String]
        }
        
        return list!.getItemIDs()
    }
    
    func insert(item: Item, atFront front: Bool) throws -> Int {
        var index = 0
        if front {
            items.insert(item.ID, at: 0)
        } else {
            items.append(item.ID)
            index = items.count - 1
        }
        numItems += 1
        
        do {
            try saveListToFile()
        } catch let error as Status {
            throw error
        } catch {
            throw error
        }
        
        return index
    }
    
    func removeItem(atIndex index: Int) throws {
        if index < 0 || index >= numItems {
            throw Status.ErrorIndex
        }
        
        items.remove(at: index)
        numItems -= 1
        
        do {
            try saveListToFile()
        } catch let error as Status {
            throw error
        } catch {
            throw error
        }
    }
    
    func exchangeItem(fromIndex src: Int, toIndex dst: Int) {
        if src < 0 || dst < 0 || src >= numItems || dst >= numItems {
            return
        }
        
        swap(&items[src], &items[dst])
    }
    
    // MARK: -
}

extension List: JSON {
    // MARK: JSON Protocol
    
    func toJSONString() -> String? {
        var dict: JSONDictionary = [:]
        dict["version"] = version as JSONObject?
        dict["name"] = name as JSONObject?
        dict["ID"] = ID as JSONObject?
        dict["numItems"] = numItems as JSONObject?
        dict["items"] = items as JSONObject?
        
        let jsonString = Utils.getJSONFromObject(dict as JSONObject?)
        Utils.debugLog("Serialized list to JSON string \(jsonString)")
        
        return jsonString
    }
    
    static func fromJSONString(_ input: String?) -> List? {
        guard input != nil else {
            return nil
        }
        
        let dict = Utils.getDictionaryFromJSON(input)
        guard dict != nil else {
            return nil
        }
        
        guard let version = dict!["version"] as? String else {
            Utils.debugLog("Item version invalid")
            return nil
        }
        guard let name = dict!["name"] as? String else {
            Utils.debugLog("List name invalid")
            return nil
        }
        guard let ID = dict!["ID"] as? String else {
            Utils.debugLog("List ID invalid")
            return nil
        }
        guard let numItems = dict!["numItems"] as? Int else {
            Utils.debugLog("List numItems invalid")
            return nil
        }
        guard let items = dict!["items"] as? [String] else {
            Utils.debugLog("List items invalid")
            return nil
        }
        
        let list = List(name: name, ID: ID, numItems: numItems, items: items)
        if !list.setVersion(version) {
            return nil
        }
        
        return list
    }
}
