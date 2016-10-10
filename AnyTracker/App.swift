//
//  App.swift
//  AnyTracker
//
//  Created by Cristian Sava on 10/02/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import UIKit
import Foundation

enum Status: String, Error {
    case ErrorDefault = "Unknown error"
    case ErrorInputString = "Bad input found!"
    case ErrorIndex = "Index error"
    
    case ErrorFailedToAddList = "Failed to add list. Try again later"
    case ErrorListsFileSave = "Could not save lists data"
    case ErrorListsFileLoad = "Failed to load lists data"
    case ErrorListsBadCache = "Corrupted data!"
    case ErrorListFileSave = "Could not save list. Try again later"
    case ErrorListFileLoad = "Failed to load list"
    case ErrorListDelete = "Failed to delete list"
    
    case ErrorItemBadID = "Wrong item ID. Please try again"
    case ErrorItemFileSave = "Could not save item. Try again later"
    case ErrorItemFileLoad = "Failed to load item"
    
    case ErrorJSONDeserialize = "Could not load data: corrupted/invalid format"
    case ErrorJSONSerialize = "Failed to serialize data"
    
    func createErrorAlert() -> UIAlertController {
        var title: String;
        switch self {
        case .ErrorDefault, .ErrorInputString, .ErrorIndex:
            title = "Fatal error"
        case .ErrorFailedToAddList, .ErrorListsFileSave, .ErrorListsFileLoad, .ErrorListsBadCache,
             .ErrorListFileSave, .ErrorListFileLoad, .ErrorListDelete, .ErrorItemBadID, .ErrorItemFileSave, .ErrorItemFileLoad,
             .ErrorJSONDeserialize, .ErrorJSONSerialize:
            title = "Error"
        }
        
        let alert = UIAlertController(title: title, message: self.rawValue, preferredStyle: UIAlertControllerStyle.alert)
        let defaultAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
        alert.addAction(defaultAction)
        
        return alert
    }
}

class App {
    struct Constants {
        struct Key {
            static let noContent = "NoContent"
            static let numberSeparator = "NumberSeparator"
            static let dateFormatLong = "DateFormatLong"
            static let addNewListTop = "AddNewListTop"
            static let addNewItemTop = "AddNewItemTop"
        }
        
        struct Text {
            static let listAll = "ALL"
            static let listItems = " Items"
        }
        
        struct File {
            static let ext = ".json"
            static let lists = "lists.json"
            static let list = "list"
            static let item = "item"
        }
        
        struct Limits {
            static let itemsPerList = 128
        }
        
        struct Colors {
            static let ItemSum = UIColor(red: 0, green: 122, blue: 255)
            static let ItemCounter = UIColor(red: 85, green: 205, blue: 0)
            static let ItemJournal = UIColor(red: 255, green: 132, blue: 0)
        }
        
        struct Animations {
            static let keyboardDuration = 0.3
            static let keyboardCurve = UIViewAnimationCurve.easeOut
            static let keyboardDistanceToControl: CGFloat = 10
        }
    }
    
    
    static fileprivate(set) var version: String = {
        let appPlist = Bundle.main.infoDictionary as [String: AnyObject]!
        return appPlist!["CFBundleShortVersionString"] as! String
    }()
    
    // Array of lists ID
    var lists: Lists?
    
    // Settings
    fileprivate(set) var noContent: Bool
    fileprivate(set) var numberSeparator: Bool
    fileprivate(set) var dateFormatLong: Bool
    fileprivate(set) var addNewListTop: Bool
    fileprivate(set) var addNewItemTop: Bool
    
    
    init(noContent: Bool, numberSeparator: Bool, dateFormatLong: Bool, addNewListTop: Bool, addNewItemTop: Bool) {
        self.noContent = noContent
        self.numberSeparator = numberSeparator
        self.dateFormatLong = dateFormatLong
        self.addNewListTop = addNewListTop
        self.addNewItemTop = addNewItemTop
        
        Utils.debugLog("Initialized a new App instance with settings \(self.noContent),\(self.numberSeparator),\(self.dateFormatLong),\(self.addNewListTop),\(self.addNewItemTop)")
    }
    
    func appInit() {
        Utils.debugLog("App init...")
        
        setupDefaultValues()
        loadSettings()
    }

    func appPause() {
        Utils.debugLog("App moves to inactive state...")
    }

    func appResume() {
        Utils.debugLog("App moves to active state...")
    }

    func appExit() {
        Utils.debugLog("App will terminate...")
    }
    
    fileprivate func setupDefaultValues() {
        let defaultPrefsFile = Bundle.main.url(forResource: "DefaultSettings", withExtension: "plist")
        if let prefsFile = defaultPrefsFile {
            let defaultPrefs = NSDictionary(contentsOf: prefsFile) as! [String : AnyObject]
        
            UserDefaults.standard.register(defaults: defaultPrefs)
        } else {
            Utils.debugLog("DefaultSettings not found in bundle!")
        }
    }
    
    fileprivate func loadSettings() {
        noContent = UserDefaults.standard.bool(forKey: Constants.Key.noContent)
        numberSeparator = UserDefaults.standard.bool(forKey: Constants.Key.numberSeparator)
        dateFormatLong = UserDefaults.standard.bool(forKey: Constants.Key.dateFormatLong)
        addNewListTop = UserDefaults.standard.bool(forKey: Constants.Key.addNewListTop)
        addNewItemTop = UserDefaults.standard.bool(forKey: Constants.Key.addNewItemTop)
    }
    
    func toggleNoContent() {
        Utils.debugLog("toggleNoContent")
        
        noContent = !noContent
        UserDefaults.standard.set(noContent, forKey: Constants.Key.noContent)
    }
    
    func toggleNumberSeparator() {
        Utils.debugLog("toggleNumberSeparator")
        
        numberSeparator = !numberSeparator
        UserDefaults.standard.set(numberSeparator, forKey: Constants.Key.numberSeparator)
    }
    
    func toggleDateFormatLong() {
        Utils.debugLog("toggleDateFormatLong")
        
        dateFormatLong = !dateFormatLong
        UserDefaults.standard.set(dateFormatLong, forKey: Constants.Key.dateFormatLong)
    }
    
    func toggleAddNewListTop() {
        Utils.debugLog("toggleAddNewListTop")
        
        addNewListTop = !addNewListTop
        UserDefaults.standard.set(addNewListTop, forKey: Constants.Key.addNewListTop)
    }
    
    func toggleAddNewItemTop() {
        Utils.debugLog("toggleAddNewItemTop")
        
        addNewItemTop = !addNewItemTop
        UserDefaults.standard.set(addNewItemTop, forKey: Constants.Key.addNewItemTop)
    }
}
