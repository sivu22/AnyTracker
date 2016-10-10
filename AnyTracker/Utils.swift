//
//  Utils.swift
//  AnyTracker
//
//  Created by Cristian Sava on 14/02/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import Foundation
import UIKit

typealias JSONObject = AnyObject
typealias JSONDictionary = [String: JSONObject]
typealias JSONArray = [JSONObject]


struct Utils {    
    static fileprivate(set) var documentsPath: String = {
        let fileManager = FileManager.default
        let URLs = fileManager.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)
        
        Utils.debugLog("documentsPath = " + URLs[0].path)
        return URLs[0].path
    }()
    
    
    static func debugLog(_ text: String, functionName: String = #function, lineNumber: Int = #line) {
        #if DEBUG
            print("\(functionName):\(lineNumber)  \(text)")
        #endif
    }
    
    static func validString(_ string: String?) -> Bool {
        if (string ?? "").isEmpty {
            return false
        }
        
        return true
    }
    
    static func errorInfo(_ error: NSError?) -> String {
        guard error != nil else {
            return ""
        }
        guard error!.userInfo[NSUnderlyingErrorKey] != nil else {
            return error!.localizedDescription
        }
        
        // Much more useful
        return (error!.userInfo[NSUnderlyingErrorKey]! as AnyObject).localizedDescription
    }
    
    static func currentTime() -> String {
        return timeFromDate(Date())
    }
    
    static func timeFromDate(_ date: Date) -> String {
        return String(Int64(date.timeIntervalSince1970))
    }
    
    static func dateFromTime(_ timeIntervalSince1970: String?) -> Date? {
        guard let timeString = timeIntervalSince1970 else {
            return nil
        }
        guard let time = Double(timeString) else {
            return nil
        }
        
        return Date(timeIntervalSince1970: time)
    }
    
    static func stringFrom(date: Date?, startDate: Bool, longFormat: Bool) -> String {
        if startDate {
            return "From " + stringFrom(date: date, longFormat: longFormat)
        } else {
            return "To " + stringFrom(date: date, longFormat: longFormat)
        }
    }
    
    static func stringFrom(date: Date?, longFormat: Bool) -> String {
        guard let date = date else {
            return ""
        }
        
        let dateFormatter = DateFormatter()
        if longFormat {
            dateFormatter.dateStyle = DateFormatter.Style.long
        } else {
            dateFormatter.dateStyle = DateFormatter.Style.short
        }
        return dateFormatter.string(from: date)
    }
    
    // MARK: - Files
    
    static func fileExists(atPath path: String?) -> Bool {
        guard validString(path) else {
            debugLog("Invalid path")
            return false
        }
        
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: path!);
    }
    
    fileprivate static func createFile(atPath path: String?, withContent content: String?, overwriteExisting overwrite: Bool = false) -> Bool {
        guard validString(path) else {
            debugLog("Invalid path")
            return false
        }
        
        let fileManager = FileManager.default
        if !overwrite && fileManager.fileExists(atPath: path!) {
            debugLog("File \(path) already exists")
            return false
        }
        
        if !fileManager.createFile(atPath: path!, contents: nil, attributes: nil) {
            debugLog("Failed to create file \(path)")
            return false
        }
        
        if validString(content) {
            do {
                try content!.write(toFile: path!, atomically: true, encoding: String.Encoding.utf8)
            } catch let error as NSError {
                debugLog("Couldn't write to \(path)! error " + errorInfo(error))
                return false
            }
        }
        
        return true
    }
    
    static func createFile(withName fileName: String?, withContent content: String?, overwriteExisting overwrite: Bool = false) -> Bool {
        guard validString(fileName) else {
            debugLog("Invalid filename")
            return false
        }
        
        return createFile(atPath: documentsPath + "/" + fileName!, withContent: content, overwriteExisting: overwrite)
    }
    
    static func readFile(withName fileName: String?) -> String? {
        guard validString(fileName) else {
            debugLog("Invalid filename")
            return nil
        }
        
        let filePath = documentsPath + "/" + fileName!
        let content: String?
        do {
            content = try String(contentsOfFile: filePath, encoding: String.Encoding.utf8)
        } catch let error as NSError {
            debugLog("Failed to load content of \(filePath)! error " + errorInfo(error))
            return nil
        }
        
        return content
    }
    
    static func deleteFile(atPath path: String?) -> Bool {
        guard fileExists(atPath: path) else {
            debugLog("File \(path) doesn't exist")
            return false
        }
        
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(atPath: path!)
        } catch let error as NSError {
            debugLog("Failed to delete file \(path)! error " + errorInfo(error))
            return false
        }
        
        return true
    }
    
    // MARK: - JSON
    
    static func getDictionaryFromJSON(_ input: String?) -> JSONDictionary? {
        guard validString(input) else {
            debugLog("Bad input")
            return nil
        }
        
        guard let data = input!.data(using: String.Encoding.utf8) else {
            debugLog("Failed to convert input to byte data")
            return nil
        }
        
        let jsonDict: JSONDictionary?
        do {
            jsonDict = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions()) as? JSONDictionary
        } catch let error as NSError {
            debugLog("Failed to deserialize JSON into a dictionary! error " + errorInfo(error))
            return nil
        }
        
        return jsonDict
    }
    
    static func getArrayFromJSON(_ input: String?) ->JSONArray? {
        guard validString(input) else {
            debugLog("Bad input")
            return nil
        }
        
        guard let data = input!.data(using: String.Encoding.utf8) else {
            debugLog("Failed to convert input to byte data")
            return nil
        }
        
        let jsonArray: JSONArray?
        do {
            jsonArray = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions()) as? JSONArray
        } catch let error as NSError {
            debugLog("Failed to deserialize JSON into an array! error " + errorInfo(error))
            return nil
        }
        
        return jsonArray
    }
    
    static func getJSONFromObject(_ input: JSONObject?) -> String? {
        guard input != nil else {
            debugLog("Bad input")
            return nil
        }
        
        let jsonString: String?
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: input! as AnyObject, options: JSONSerialization.WritingOptions())
            jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
        } catch let error as NSError {
            debugLog("Failed to serialize JSON from array! error " + errorInfo(error))
            return nil
        }
        
        return jsonString
    }
    
    // MARK: - Views
    
    static func snapshotFromView(_ view: UIView) -> UIView {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0.0)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let snapshot: UIView = UIImageView(image: image)
        snapshot.layer.masksToBounds = false
        snapshot.layer.cornerRadius = 0.0
        snapshot.layer.shadowOffset = CGSize(width: -5.0, height: 0.0)
        snapshot.layer.shadowRadius = 0.0
        snapshot.layer.shadowOpacity = 0.4
        
        return snapshot
    }
    
    static func addDoneButton(toTextField textField: UITextField, forTarget target: Any?, negativeTarget: AnyObject?, negativeSelector: Selector) {
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.backgroundColor = UIColor.white
        keyboardToolbar.sizeToFit()
        let negativeBarButton = UIBarButtonItem(title: "+/-", style: .plain,
                                            target: negativeTarget, action: negativeSelector)
        let flexBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                            target: nil, action: nil)
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done,
                                            target: target, action: #selector(UIView.endEditing(_:)))
        keyboardToolbar.items = [negativeBarButton, flexBarButton, doneBarButton]
        textField.inputAccessoryView = keyboardToolbar
    }
    
    static func addDoneButton(toDateTextField textField: UITextField, forTarget target: Any?, doneSelector selector: Selector? = nil) {
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.backgroundColor = UIColor.white
        keyboardToolbar.sizeToFit()
        let flexBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                            target: nil, action: nil)
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: target, action: selector == nil ? #selector(UIView.endEditing(_:)) : selector)
        keyboardToolbar.items = [flexBarButton, doneBarButton]
        textField.inputAccessoryView = keyboardToolbar
    }
    
    static func addDoneButton(toTextView textView: UITextView, forTarget target: Any?, doneSelector selector: Selector? = nil) {
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.backgroundColor = UIColor.white
        keyboardToolbar.sizeToFit()
        let flexBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                            target: nil, action: nil)
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: target, action: selector == nil ? #selector(UIView.endEditing(_:)) : selector)
        keyboardToolbar.items = [flexBarButton, doneBarButton]
        textView.inputAccessoryView = keyboardToolbar
    }
}

// MARK: - Extensions

extension Double {
    var isInt: Bool {
        return self.truncatingRemainder(dividingBy: 1) == 0
    }
    
    func asString(withSeparator separator: Bool = false) -> String {
        if separator {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = NumberFormatter.Style.decimal
            if isInt {
                return numberFormatter.string(from: NSNumber(value: Int64(self)))!
            } else {
                return numberFormatter.string(from: NSNumber(value: self))!
            }
        } else {
            if isInt {
                return String(Int64(self))
            } else {
                return String(self)
            }
        }
    }
}

extension UInt {
    func asString(withSeparator separator: Bool = false) -> String {
        if separator {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = NumberFormatter.Style.decimal
            return numberFormatter.string(from: NSNumber(value: self))!
        } else {
            return String(self)
        }
    }
}

extension UIColor {
    func getRGBA() -> (red: Int, green: Int, blue: Int, alpha: Int)? {
        var flRed: CGFloat = 0
        var flGreen: CGFloat = 0
        var flBlue: CGFloat = 0
        var flAlpha: CGFloat = 0
        
        if self.getRed(&flRed, green: &flGreen, blue: &flBlue, alpha: &flAlpha) {
            return (red: Int(flRed * 255), green: Int(flGreen * 255), blue: Int(flBlue * 255), alpha: Int(flAlpha * 255))
        } else {
            return nil
        }
    }
    
    func getRGBAString() -> String {
        if let (red, green, blue, alpha) = self.getRGBA() {
            return "R:\(red),G:\(green),B:\(blue),A:\(alpha)"
        }
        
        return "Error"
    }
    
    convenience init(red: Int, green: Int, blue: Int) {
        let flRed = CGFloat(red) / 255
        let flGreen = CGFloat(green) / 255
        let flBlue = CGFloat(blue) / 255
        
        self.init(red: flRed, green: flGreen, blue: flBlue, alpha: 1.0)
    }
}

extension UIButton {
    func enable() {
        isEnabled = true
        alpha = 1
    }
    
    func disable() {
        isEnabled = false
        alpha = 0.3
    }
}
