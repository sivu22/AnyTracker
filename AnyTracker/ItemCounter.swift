//
//  ItemCounter.swift
//  AnyTracker
//
//  Created by Cristian Sava on 19/08/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import Foundation

class ItemCounter: Item, ItemTypeCounter {
    var version: String = App.version
    
    var name: String = ""
    var ID: String = ""
    var description: String = ""
    fileprivate(set) var type: ItemType = ItemType.counter
    var useDate: Bool = false
    var startDate: Date
    var endDate: Date
    
    fileprivate(set) var counter: UInt = 0
    
    required init() {
        self.startDate = Date()
        self.endDate = self.startDate
    }
    
    convenience init(withName name: String, ID: String, description: String, useDate: Bool, startDate: Date, endDate: Date, counter: UInt = 0) {
        self.init()
        initItem(withName: name, ID: ID, description: description, useDate: useDate, startDate: startDate, endDate: endDate)
        
        self.counter = counter
    }
    
    func isEmpty() -> Bool {
        return counter == 0
    }
    
    func toString() -> String? {
        return toJSONString()
    }
    
    func changeCounter(byIncreasing increasing: Bool, completionHandler: @escaping (Status?) -> Void) {
        let oldCounter = counter
        if increasing {
            counter += 1
        } else if counter > 0 {
            counter -= 1
        }
        
        DispatchQueue.global().async {
            var completionError: Status?
            do {
                try self.saveToFile()
            } catch let error as Status {
                self.counter = oldCounter
                completionError = error
            } catch {
                self.counter = oldCounter
                completionError = Status.errorDefault
            }
            
            DispatchQueue.main.async {
                completionHandler(completionError)
            }
        }
    }
    
    // MARK: -
}

extension ItemCounter: JSON {
    // MARK: JSON Protocol
    
    func toJSONString() -> String? {
        var dict: JSONDictionary = getItemAsJSONDictionary()
        
        dict["counter"] = counter as JSONObject?
        
        let jsonString = Utils.getJSONFromObject(dict as JSONObject?)
        Utils.debugLog("Serialized counter item to JSON string \(jsonString)")
        
        return jsonString
    }
    
    static func fromJSONString(_ input: String?) -> ItemCounter? {
        guard let (dict, version, name, ID, description, type, useDate, startDate, endDate) = getItemFromJSONDictionary(input) else {
            return nil
        }
        
        Utils.debugLog(input!)
        if type != ItemType.counter.rawValue {
            Utils.debugLog("Item is not of type counter")
            return nil
        }
        
        guard let counter = dict["counter"] as? UInt else {
            Utils.debugLog("Item counter invalid")
            return nil
        }
        
        let itemCounter = ItemCounter(withName: name, ID: ID, description: description, useDate: useDate, startDate: startDate, endDate: endDate, counter: counter)
        if !itemCounter.setVersion(version) {
            return nil
        }
        
        return itemCounter
    }
}
