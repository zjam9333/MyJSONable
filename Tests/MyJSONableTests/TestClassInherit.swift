//
//  File.swift
//  
//
//  Created by zjj on 2024/5/11.
//

import Foundation
import XCTest

#if canImport(MyJSONable)

import MyJSONable

final class TestClassInherit: XCTestCase {
    @JSONableMacro
    class ClassRoot00: NSObject, JSONable {
        var boolVal: Bool?
        var doubleVal: Double?
        var intVal: Int?
        var stringVal: String?
        
        override required init() {
            super.init()
        }
    }
    
    @JSONableSubclassMacro
    class ClassLeave33: ClassRoot00 {
        var name: String?
    }
    
    func testClassesInherit() throws {
        let json: [String: Any] = [
            "boolVal": 999,
            "doubleVal": "3.14",
            "intVal": "999",
            "stringVal": 1999.99,
            "name": "hello"
        ]
        let ca = ClassLeave33(fromJson: json)
        XCTAssert(ca.doubleVal == 3.14)
        XCTAssert(ca.name == "hello")
    }
}
#endif

//@JSONableMacro
//class ClassRoot00: JSONable {
//    var boolVal: Bool?
//    var doubleVal: Double?
//    var intVal: Int?
//    var stringVal: String?
//    
//    required init() {}
//}
//
//class ClassLeave33: ClassRoot00 {
//    
//}

