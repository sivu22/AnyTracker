//
//  Lists.swift
//  AnyTracker
//
//  Created by Cristian Sava on 11/03/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import Foundation

class Lists {
    struct ListInfo {
        var name: String
        var numItems: Int
    }
    
    struct ListsCache {
        var numItemsAll: Int
        var lists: [ListInfo]
    }
    
    // Used for reducing disk access (Lists ViewController)
    fileprivate(set) var cache: ListsCache?
    
    fileprivate(set) var listsData: [String]
    
    init() {
        listsData = []
        cache = ListsCache(numItemsAll: 0, lists: [])
    }
    
    init(listsData: [String]) {
        self.listsData = listsData
        cache = ListsCache(numItemsAll: 0, lists: [])
        if listsData.count > 0 {
            if !buildCache() {
                cache = nil
            }
        }
    }
    
    // MARK: - Lists operations
    
    func getListIDs() -> [String] {
        return listsData
    }
    
    func saveListsToFile() throws {
        guard let JSONString = toJSONString() else {
            Utils.debugLog("Failed to serialize JSON lists")
            throw Status.errorJSONSerialize
        }
        
        if !Utils.createFile(withName: Constants.File.lists, withContent: JSONString, overwriteExisting: true) {
            Utils.debugLog("Failed to save lists to file")
            throw Status.errorListsFileSave
        }
    }
    
    static func loadListsFromFile() throws -> Lists {
        let content = Utils.readFile(withName: Constants.File.lists)
        guard content != nil else {
            Utils.debugLog("Failed to load lists from file")
            throw Status.errorListsFileLoad
        }
        
        guard let lists = fromJSONString(content) else {
            Utils.debugLog("Failed to deserialize JSON lists")
            throw Status.errorJSONDeserialize
        }

        return lists
    }
    
    func insertList(withName name: String, atFront front: Bool) throws -> Int {
        var newList: List
        do {
            newList = try List.createList(withName: name)
            try newList.saveListToFile()
        } catch let error as Status {
            throw error
        } catch {
            throw Status.errorDefault
        }
        
        var index = 0
        if front {
            listsData.insert(newList.ID, at: 0)
        } else {
            listsData.append(newList.ID)
            index = listsData.count - 1
        }
        
        // Keep cache in sync
        if !insertCache(atIndex: index) {
            Utils.debugLog("Failed to update cache, will remove the added list")
            // Failure
            if index == 0 {
                listsData.removeFirst()
            } else {
                listsData.removeLast()
            }
            index = -1
        }
        
        return index
    }
    
    // Doesn't throw or fail because it's only a cosmetic change for the ALL list
    func changedList(atIndex index: Int, withNumItems numItems: Int) {
        Utils.debugLog("Will update cache at index \(index) with numItems \(numItems)")
        if !updateCache(atIndex: index, withNumItems: numItems) {
            Utils.debugLog("Failed to update cache at index \(index)")
        }
    }
    
    fileprivate func clearList(withName listName: String) {
        var list: List?
        do {
            list = try List.loadListFromFile(listName)
        } catch {
            Utils.debugLog("Failed to load list \(listName): \(error)")
        }
        
        for item in list!.items {
            let filePath = Utils.documentsPath + "/" + item
            if !Utils.deleteFile(atPath: filePath) {
                Utils.debugLog("Failed to delete item \(item)")
            } else {
                Utils.debugLog("Deleted file \(item)")
            }
        }
    }
    
    func updateList(atIndex index: Int, withNewName newName: String) throws {
        guard index >= 0 && index < listsData.count else {
            Utils.debugLog("Bad list index \(index)")
            return
        }
        
        var list: List?
        do {
            list = try List.loadListFromFile(listsData[index])
            try list!.updateList(withName: newName)
        } catch {
            throw error
        }
        
        if !updateCache(atIndex: index, withName: newName) {
            Utils.debugLog("Failed to update cache at index \(index)")
        }
    }
    
    func deleteLists() throws {
        if listsData.count == 0 {
            Utils.debugLog("No lists to clear")
            return
        }
        
        for list in listsData {
            clearList(withName: list)
            
            let filePath = Utils.documentsPath + "/" + list
            if !Utils.deleteFile(atPath: filePath) {
                Utils.debugLog("Failed to delete list \(list)")
            } else {
                Utils.debugLog("Deleted file \(list)")
            }
        }
        listsData.removeAll();
        
        clearCache();
        
        do {
            try saveListsToFile()
        } catch let error as Status {
            throw error
        }
        
        Utils.debugLog("Successfully cleared app data")
    }
    
    // Delete required lists and returns number of items the list had (-1 if error)
    func deleteList(atIndex index: Int) -> Int {
        guard index >= 0 && index < listsData.count else {
            Utils.debugLog("Bad index")
            return -1
        }
        
        let numItems = cache?.lists[index].numItems ?? -1
        
        let listID = listsData[index]
        clearList(withName: listID)
        
        listsData.remove(at: index)
        let _ = removeCache(atIndex: index)
        
        let filePath = Utils.documentsPath + "/" + listID
        if !Utils.deleteFile(atPath: filePath) {
            Utils.debugLog("Failed to delete list at index \(index)")
            return -1
        } else {
            Utils.debugLog("Deleted file \(listID)")
        }
        
        Utils.debugLog("Successfully deleted list at index \(index)")
        return numItems
    }
    
    func exchangeList(fromIndex src: Int, toIndex dst: Int) {
        if src < 0 || dst < 0 || src >= listsData.count || dst >= listsData.count {
            return
        }
        
        swap(&listsData[src], &listsData[dst])
        swapCache(atIndex: src, withIndex: dst)
    }
    
    func getListNumItems(atIndex index: Int) -> Int {
        return getCacheNumItems(atIndex: index)
    }
    
    // MARK: -
}

extension Lists: JSON {
    // MARK: JSON Protocol
    
    func toJSONString() -> String? {
        let jsonString = Utils.getJSONFromObject(listsData as JSONObject)
        Utils.debugLog("Serialized lists to JSON string \(String(describing: jsonString))")
        
        return jsonString
    }
    
    static func fromJSONString(_ input: String?) -> Lists? {
        guard input != nil else {
            return nil
        }
        
        let dict = Utils.getArrayFromJSON(input)
        guard dict != nil else {
            return nil
        }
        
        guard let listsData = dict! as? [String] else {
            return nil
        }
        
        return Lists(listsData: listsData)
    }
    
    // MARK: -
}

// Cache is used only for displaying Lists ViewController and minimize disk access
private extension Lists {
    // MARK: - Cache
    
    func buildCache() -> Bool {
        guard cache != nil else {
            Utils.debugLog("Cache missing!")
            return false
        }
        
        do {
            for list in listsData {
                let listData = try List.loadListFromFile(list)
                let listInfo = ListInfo(name: listData.name, numItems: listData.numItems)
                
                cache!.numItemsAll += listInfo.numItems
                cache!.lists.append(listInfo)
            }
        } catch {
            Utils.debugLog("Failed to load specific list")
            return false
        }
        
        return true
    }
    
    func clearCache() {
        guard cache != nil else {
            Utils.debugLog("Cache missing!")
            return
        }
        
        cache!.numItemsAll = 0
        cache!.lists.removeAll()
        Utils.debugLog("Cache cleared")
    }
    
    func insertCache(atIndex index: Int) -> Bool {
        guard cache != nil else {
            Utils.debugLog("Cache missing!")
            return false
        }
        guard index < listsData.count && index >= 0 else {
            Utils.debugLog("Index out of bounds")
            return false
        }
        
        do {
            let listData = try List.loadListFromFile(listsData[index])
            let listInfo = ListInfo(name: listData.name, numItems: listData.numItems)
                
            cache!.numItemsAll += listInfo.numItems
            cache!.lists.insert(listInfo, at: index)
            Utils.debugLog("Updated cache at index \(index): \(listInfo.name), \(listInfo.numItems)")
            Utils.debugLog("Total items: \(cache!.numItemsAll)")
        } catch {
            Utils.debugLog("Failed to load specific list")
            return false
        }
        
        return true
    }
    
    func updateCache(atIndex index: Int, withNumItems numItems: Int) -> Bool {
        guard cache != nil else {
            Utils.debugLog("Cache missing!")
            return false
        }
        guard index < listsData.count && index >= 0 else {
            Utils.debugLog("Index out of bounds")
            return false
        }
        
        cache!.numItemsAll += numItems - cache!.lists[index].numItems
        cache!.lists[index].numItems = numItems
        
        return true
    }
    
    func updateCache(atIndex index: Int, withName name: String) -> Bool {
        guard cache != nil else {
            Utils.debugLog("Cache missing!")
            return false
        }
        guard index < listsData.count && index >= 0 else {
            Utils.debugLog("Index out of bounds")
            return false
        }
        
        cache!.lists[index].name = name
        
        return true
    }
    
    func removeCache(atIndex index: Int) -> Bool {
        guard cache != nil else {
            Utils.debugLog("Cache missing!")
            return false
        }
        guard index < cache!.lists.count && index >= 0 else {
            Utils.debugLog("Index out of bounds")
            return false
        }
        
        let listInfo = cache!.lists.remove(at: index)
        cache!.numItemsAll -= listInfo.numItems
        Utils.debugLog("Removed from cache at index \(index): \(listInfo.name), \(listInfo.numItems)")
        
        return true
    }
    
    func getCacheNumItems(atIndex index: Int) -> Int {
        guard let cache = cache else {
            Utils.debugLog("Cache missing!")
            return -1
        }
        guard index < cache.lists.count && index >= 0 else {
            Utils.debugLog("Index out of bounds")
            return -1
        }
        
        return cache.lists[index].numItems;
    }
    
    func swapCache(atIndex src: Int, withIndex dst: Int) {
        guard cache != nil else {
            Utils.debugLog("Cache missing!")
            return
        }
        if src < 0 || dst < 0 || src >= listsData.count || dst >= listsData.count {
            return
        }
        
        swap(&cache!.lists[src], &cache!.lists[dst])
    }
}
