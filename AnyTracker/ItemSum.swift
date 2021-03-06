//
//  ItemSum.swift
//  AnyTracker
//
//  Created by Cristian Sava on 10/07/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import Foundation

class ItemSum: Item, ItemTypeSum {
    var version: String = App.version
    
    var name: String = ""
    var ID: String = ""
    var description: String = ""
    fileprivate(set) var type: ItemType = ItemType.sum
    var useDate: Bool = false
    var startDate: Date
    var endDate: Date
    
    fileprivate(set) var sum: Double = 0
    fileprivate(set) var elements: [Element] = []
    
    required init() {
        self.startDate = Date()
        self.endDate = self.startDate
    }
    
    convenience init(withName name: String, ID: String, description: String, useDate: Bool, startDate: Date, endDate: Date, sum: Double = 0, elements: [Element] = []) {
        self.init()
        initItem(withName: name, ID: ID, description: description, useDate: useDate, startDate: startDate, endDate: endDate)
        
        self.sum = sum
        self.elements = elements
    }
    
    func isEmpty() -> Bool {
        return elements.count == 0
    }
    
    func toString() -> String? {
        return toJSONString()
    }
    
    func insert(element: Element, completionHandler: @escaping (Status?) -> Void) {
        elements.append(element)
        sum += element.value
        
        DispatchQueue.global().async {
            var completionError: Status?
            do {
                try self.saveToFile()
            } catch {
                self.elements.removeLast()
                self.sum -= element.value
                if let statusError = error as? Status {
                    completionError = statusError
                } else {
                    completionError = Status.errorDefault
                }
            }
            
            DispatchQueue.main.async {
                completionHandler(completionError)
            }
        }
    }
    
    func remove(atIndex index: Int, completionHandler: @escaping (Status?) -> Void) {
        if index < 0 || index >= elements.count {
            completionHandler(Status.errorIndex)
            return
        }
        
        let deleted = Element(name: elements[index].name, value: elements[index].value)
        sum -= elements[index].value
        elements.remove(at: index)
        
        DispatchQueue.global().async {
            var completionError: Status?
            do {
                try self.saveToFile()
            } catch {
                self.elements.append(deleted)
                self.sum += deleted.value
                if let statusError = error as? Status {
                    completionError = statusError
                } else {
                    completionError = Status.errorDefault
                }
            }
            
            DispatchQueue.main.async {
                completionHandler(completionError)
            }
        }
    }
    
    func updateElement(atIndex index: Int, newName name: String, newValue value: Double, completionHandler: @escaping (Status?) -> Void) {
        if index < 0 || index >= elements.count {
            completionHandler(Status.errorIndex)
            return
        }
        
        if elements[index].name == name && elements[index].value == value {
            return
        }
        
        let old = Element(name: elements[index].name, value: elements[index].value)
        let new = Element(name: name, value: value)
        sum -= old.value
        sum += new.value
        elements[index] = new
        
        DispatchQueue.global().async {
            var completionError: Status?
            do {
                try self.saveToFile()
            } catch {
                self.elements[index] = old
                self.sum -= new.value
                self.sum += old.value
                if let statusError = error as? Status {
                    completionError = statusError
                }
            }
            
            DispatchQueue.main.async {
                completionHandler(completionError)
            }
        }
    }
    
    func exchangeElement(fromIndex src: Int, toIndex dst: Int) {
        if src < 0 || dst < 0 || src >= elements.count || dst >= elements.count {
            return
        }
        
        elements.swapAt(src, dst)
    }
    
    // MARK: -
}

extension ItemSum: JSON {
    // MARK: JSON Protocol
    
    func toJSONString() -> String? {
        var dict: JSONDictionary = getItemAsJSONDictionary()
        
        dict["sum"] = sum as JSONObject?
        var arrayElements: JSONArray = []
        for element in elements {
            var dictElement: JSONDictionary = [:]
            dictElement["name"] = element.name as JSONObject?
            dictElement["value"] = element.value as JSONObject?
            
            arrayElements.append(dictElement as JSONObject)
        }
        dict["elements"] = arrayElements as JSONObject?
        
        let jsonString = Utils.getJSONFromObject(dict as JSONObject?)
        Utils.debugLog("Serialized sum item to JSON string \(String(describing: jsonString))")
        
        return jsonString
    }
    
    static func fromJSONString(_ input: String?) -> ItemSum? {
        guard let (dict, version, name, ID, description, type, useDate, startDate, endDate) = getItemFromJSONDictionary(input) else {
            return nil
        }
        
        Utils.debugLog(input!)
        if type != ItemType.sum.rawValue {
            Utils.debugLog("Item is not of type sum")
            return nil
        }
        
        guard let sum = dict["sum"] as? Double else {
            Utils.debugLog("Item sum invalid")
            return nil
        }
        guard let elementsArray = dict["elements"] as? [AnyObject] else {
            Utils.debugLog("Item elements are invalid")
            return nil
        }
        var elements: [Element] = []
        for elementObject in elementsArray {
            if let name = elementObject["name"] as? String, let value = elementObject["value"] as? Double {
                let element = Element(name: name, value: value)
                elements.append(element)
                Utils.debugLog(element.name + " " + String(element.value))
            }
        }
        
        let itemSum = ItemSum(withName: name, ID: ID, description: description, useDate: useDate, startDate: startDate, endDate: endDate, sum: sum, elements: elements)
        if !itemSum.setVersion(version) {
            return nil
        }
        
        return itemSum
    }
}
