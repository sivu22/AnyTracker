//
//  UtilsTests.swift
//  AnyTracker
//
//  Created by Cristian Sava on 03/09/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import XCTest
@testable import AnyTracker

class UtilsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDoubleExtension() {
        let d1: Double = 0
        let d2: Double = 0.0
        let d3: Double = 1
        let d4: Double = 2.2
        let d5: Double = -22
        let d6: Double = -12.68
        let d7: Double = 12345.6789
        let d8: Double = 22.00
        let d9: Double = 225631.99
        
        XCTAssertTrue(d1.isInt)
        XCTAssertTrue(d2.isInt)
        XCTAssertTrue(d3.isInt)
        XCTAssertFalse(d4.isInt)
        XCTAssertTrue(d5.isInt)
        XCTAssertFalse(d6.isInt)
        XCTAssertFalse(d7.isInt)
        XCTAssertTrue(d8.isInt)
        
        XCTAssertEqual(d1.asString(), "0")
        XCTAssertEqual(d2.asString(), "0")
        XCTAssertEqual(d3.asString(), "1")
        XCTAssertEqual(d4.asString(), "2.2")
        XCTAssertEqual(d5.asString(), "-22")
        XCTAssertEqual(d6.asString(), "-12.68")
        XCTAssertEqual(d7.asString(), "12345.6789")
        XCTAssertEqual(d8.asString(), "22")
        
        XCTAssertEqual(d7.asString(withSeparator: true), "12,345.679")
        XCTAssertEqual(d9.asString(withSeparator: true), "225,631.99")
    }
    
    func testUIntExtension() {
        let u1: UInt = 0
        let u2: UInt = 1
        let u3: UInt = 1024
        let u4: UInt = 12345
        let u5: UInt = 123456
        
        XCTAssertEqual(u1.asString(), "0")
        XCTAssertEqual(u2.asString(), "1")
        XCTAssertEqual(u3.asString(), "1024")
        XCTAssertEqual(u4.asString(), "12345")
        XCTAssertEqual(u5.asString(), "123456")
        
        XCTAssertEqual(u1.asString(withSeparator: true), "0")
        XCTAssertEqual(u2.asString(withSeparator: true), "1")
        XCTAssertEqual(u3.asString(withSeparator: true), "1,024")
        XCTAssertEqual(u4.asString(withSeparator: true), "12,345")
        XCTAssertEqual(u5.asString(withSeparator: true), "123,456")
    }
    
    func testColorExtension() {
        let c1: UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        let c2: UIColor = UIColor(red: 128, green: 128, blue: 128)
        let c3: UIColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        
        XCTAssertNotNil(c1.getRGBA())
        XCTAssertNotNil(c2.getRGBA())
        XCTAssertNotNil(c3.getRGBA())
        
        let (red1, green1, blue1, alpha1) = c1.getRGBA()!
        XCTAssertEqual(red1, 0)
        XCTAssertEqual(green1, 0)
        XCTAssertEqual(blue1, 0)
        XCTAssertEqual(alpha1, 0)
        
        let (red2, green2, blue2, alpha2) = c2.getRGBA()!
        XCTAssertEqual(red2, 128)
        XCTAssertEqual(green2, 128)
        XCTAssertEqual(blue2, 128)
        XCTAssertEqual(alpha2, 255)
        
        let (red3, green3, blue3, alpha3) = c3.getRGBA()!
        XCTAssertEqual(red3, 127)
        XCTAssertEqual(green3, 127)
        XCTAssertEqual(blue3, 127)
        XCTAssertEqual(alpha3, 127)
        
        XCTAssertEqual(c1.getRGBAString(), "R:0,G:0,B:0,A:0")
        XCTAssertEqual(c2.getRGBAString(), "R:128,G:128,B:128,A:255")
        XCTAssertEqual(c3.getRGBAString(), "R:127,G:127,B:127,A:127")
    }
    
    func testJSON() {
        // MARK: nil
        let nilObject: JSONObject? = nil
        let nilInput: String? = nil
        
        XCTAssertNil(Utils.getJSONFromObject(nilObject))
        XCTAssertNil(Utils.getArrayFromJSON(nilInput))
        XCTAssertNil(Utils.getDictionaryFromJSON(nilInput))
        
        // MARK: empty
        let arrayJSONEmpty: JSONArray = []
        let dictJSONEmpty: JSONDictionary = [:]
        
        let stringArrayEmpty = Utils.getJSONFromObject(arrayJSONEmpty as JSONObject?)
        XCTAssertNotNil(stringArrayEmpty)
        XCTAssertEqual(stringArrayEmpty, "[]")
        let arrayEmpty = Utils.getArrayFromJSON("[]")
        XCTAssertNotNil(arrayEmpty)
        XCTAssertTrue(arrayEmpty!.count == 0)
        
        let stringDictEmpty = Utils.getJSONFromObject(dictJSONEmpty as JSONObject?)
        XCTAssertNotNil(stringDictEmpty)
        XCTAssertEqual(stringDictEmpty, "{}")
        let dictEmpty = Utils.getDictionaryFromJSON("{}")
        XCTAssertNotNil(dictEmpty)
        XCTAssertTrue(dictEmpty!.count == 0)
        
        // MARK: array
        let arrayJSON: JSONArray = [1 as AnyObject, 2 as AnyObject, 3 as AnyObject]
        
        let stringArray = Utils.getJSONFromObject(arrayJSON as JSONObject?)
        XCTAssertNotNil(stringArray)
        XCTAssertEqual(stringArray, "[1,2,3]")
        var array = Utils.getArrayFromJSON("[1,2,3]")
        XCTAssertNotNil(array)
        XCTAssertTrue(array!.count == 3)
        XCTAssertTrue(array![0] as! Int == 1 && array![1] as! Int == 2 && array![2] as! Int == 3)
        array = Utils.getArrayFromJSON("[1,\"test\",\"nil\",3]")
        XCTAssertNotNil(array)
        XCTAssertTrue(array!.count == 4)
        XCTAssertTrue(array![0] as! Int == 1 && array![1] as! String == "test" && array![2] as! String == "nil" && array![3] as! Int == 3)
        
        array = Utils.getArrayFromJSON("[1,2,3")
        XCTAssertNil(array)
        array = Utils.getArrayFromJSON("1,2,3")
        XCTAssertNil(array)
        array = Utils.getArrayFromJSON("[1,\"test\",nil,3]")
        XCTAssertNil(array)
        
        // MARK: dictionary
        let dictJSON: JSONDictionary = ["key1": 1 as AnyObject, "key2": 2 as AnyObject]
        let dictJSON2: JSONDictionary = ["key1": "1" as AnyObject, "key2": 2 as AnyObject]
        
        var stringDict = Utils.getJSONFromObject(dictJSON as JSONObject?)
        XCTAssertNotNil(stringDict)
        var equal = (stringDict == "{\"key1\":1,\"key2\":2}" || stringDict == "{\"key2\":2,\"key1\":1}")
        XCTAssertTrue(equal)
        stringDict = Utils.getJSONFromObject(dictJSON2 as JSONObject?)
        XCTAssertNotNil(stringDict)
        equal = (stringDict == "{\"key1\":\"1\",\"key2\":2}" || stringDict == "{\"key2\":2,\"key1\":\"1\"}")
        XCTAssertTrue(equal)
        var dictionary = Utils.getDictionaryFromJSON("{\"key1\":1,\"key2\":2}")
        XCTAssertNotNil(dictionary)
        if let dict = dictionary {
            XCTAssertTrue(dict.count == 2 && dict["key1"] as? Int == 1 && dict["key2"] as? Int == 2)
        }
        dictionary = Utils.getDictionaryFromJSON("{\"key1\":\"1\",\"key2\":2}")
        XCTAssertNotNil(dictionary)
        if let dict = dictionary {
            XCTAssertTrue(dict.count == 2 && dict["key1"] as? String == "1" && dict["key2"] as? Int == 2)
        }
        
        dictionary = Utils.getDictionaryFromJSON("{\"key1\":\"1,\"key2\":2}")
        XCTAssertNil(dictionary)
        dictionary = Utils.getDictionaryFromJSON("{key1:\"1,\"key2\":2}")
        XCTAssertNil(dictionary)
    }
    
}
