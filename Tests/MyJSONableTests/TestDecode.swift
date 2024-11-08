//
//  File.swift
//  
//
//  Created by zjj on 2024/5/6.
//

import Foundation
import XCTest

#if canImport(MyJSONable)

import MyJSONable

final class TestDecode: XCTestCase {
    
    @JSONableMacro
    struct BasicAnimal: JSONable {
        var boolVal: Bool = false
        var doubleVal: Double = 0
        var intVal: Int = 0
        var stringVal: String = ""
        
        var optionalBool: Bool?
        var optionalInt: Int?
        var optionalDou: Double?
        var optionalStr: String?
        
        var child2: [String: Any] = [:]
    }
    
    func testBasic() throws {
        typealias Model = BasicAnimal
        let json: [String: Any] = [
            "boolVal": true,
            "doubleVal": 3.14,
            "intVal": "314",
            "stringVal": "New Dog",
            "optionalInt": "99",
            "optionalBool": 99,
            "optionalDou": "1234",
            "optionalStr": 123.5,
            "child2": [
                "age2": 100,
                "name2": "New Cow"
            ],
        ]
        let an = Model(fromJson: json)
        XCTAssert(an.boolVal == true)
        XCTAssert(an.intVal == 314)
        XCTAssert(an.child2["age2"] as! Int == 100)
        XCTAssert(an.child2["name2"] as! String == "New Cow")
        XCTAssert(an.stringVal == "New Dog")
        XCTAssert(an.optionalBool == true)
        XCTAssert(an.optionalInt == 99)
        XCTAssert(an.optionalDou == 1234)
        XCTAssert(an.optionalStr == "123.5")
    }
    
    @JSONableMacro
    struct SubAnimal: JSONable {
        var boolVal: Bool = false
        var doubleVal: Double = 0
        var intVal: Int = 0
        var stringVal: String = ""
        
        var child0: SubAnimal2 = SubAnimal2()
        var childOpt: SubAnimal2?
        var children: [SubAnimal2] = []
        
        @JSONableMacro
        struct SubAnimal2: JSONable {
            var boolVal: Bool = false
            var doubleVal: Double = 0
            var intVal: Int = 0
            var stringVal: String = ""
        }
    }
    
    func testChilren() throws {
        typealias Model = SubAnimal
        let json: [String: Any] = [
            "child0": [
                "boolVal": true,
                "doubleVal": 3.14,
                "intVal": "314",
                "stringVal": "New Dog",
            ],
            "children": [
                [
                    "boolVal": true,
                    "doubleVal": 3.14,
                    "intVal": "314",
                    "stringVal": "New Cat",
                ],
                [
                    "boolVal": true,
                    "doubleVal": 996.14,
                    "intVal": "314",
                    "stringVal": "New Dog",
                ],
            ]
        ]
        let an = Model(fromJson: json)
        XCTAssert(an.child0.doubleVal == 3.14)
        XCTAssert(an.childOpt == nil)
        XCTAssert(an.children[1].doubleVal == 996.14)
        XCTAssert(an.children[0].stringVal == "New Cat")
    }
    
    @JSONableMacro
    struct EnumAnimal: JSONable {
        var pet: Pet = .cat
        var somePet: Pet?
        var defaultPet: Pet = .fish
        
        enum Pet: String, JSONableEnum {
            case cat = "cat"
            case dog = "dog"
            case fish = "fish"
        }
    }
    
    func testEnumProperty() throws {
        typealias Model = EnumAnimal
        let json: [String: Any] = [
            "pet": "dog",
            "somePet": "cat",
            "defaultPet": "sadf",
        ]
        let an = Model(fromJson: json)
        XCTAssert(an.pet == .dog)
        XCTAssert(an.somePet == .cat)
        XCTAssert(an.defaultPet == .fish)
    }
    
    
    @JSONableMacro
    struct CustomKeyAnimal: JSONable {
        var pet: Pet = .cat
        var somePet: Pet?
        var defaultPet: Pet = .fish
        
        enum Pet: String, JSONableEnum {
            case cat = "cat"
            case dog = "dog"
            case fish = "fish"
        }
        
        func customKeyPathList() -> [JSONableKeyPathObject] {
            return [
                .init(name: "ggg", keyPath: \Self.pet)
            ]
        }
    }
    
    func testCustomKey() throws {
        typealias Model = CustomKeyAnimal
        let json: [String: Any] = [
            "ggg": "dog",
            "somePet": "cat",
            "defaultPet": "sadf",
        ]
        let an = Model(fromJson: json)
        XCTAssert(an.pet == .dog)
        XCTAssert(an.somePet == .cat)
        XCTAssert(an.defaultPet == .fish)
    }
    
    @JSONableMacro
    struct CustomSetterAnimal: JSONable {
        var pet: Pet = .cat
        var somePet: Pet?
        var defaultPet: Pet = .fish
        
        enum Pet: String, JSONableEnum {
            case cat = "cat"
            case dog = "dog"
            case fish = "fish"
        }
        
        func customKeyPathList() -> [JSONableKeyPathObject] {
            return [
                .init(name: "ggg", keyPath: \Self.pet) { p in
                    return p.rawValue
                } customSet: { j in
                    if let j = j as? Int {
                        if j > 10 {
                            return .fish
                        } else {
                            return .dog
                        }
                    }
                    return nil
                }
            ]
        }
    }
    
    func testCustomSetter() throws {
        typealias Model = CustomSetterAnimal
        let json: [String: Any] = [
            "ggg": 999,
            "somePet": "cat",
            "defaultPet": "sadf",
        ]
        let an = Model(fromJson: json)
        XCTAssert(an.pet == .fish)
        XCTAssert(an.encodeToJson().keys.contains("ggg"))
    }
    
    @JSONableMacro
    struct ValueBridgeAnimal: JSONable {
        var boolVal: Bool?
        var doubleVal: Double?
        var intVal: Int?
        var stringVal: String?
    }
    
    func testValueBridge() throws {
        typealias Model = ValueBridgeAnimal
        var an: Model
        
        an = Model()
        an.decodeFromJson(json: [
            "boolVal": 999,
            "doubleVal": "3.14",
            "intVal": "999",
            "stringVal": 1999.99
        ])
        XCTAssert(an.boolVal == true)
        XCTAssert(an.doubleVal == 3.14)
        XCTAssert(an.intVal == 999)
        XCTAssert(an.stringVal == "1999.99")
        
        an = Model()
        an.decodeFromJson(json: [
            "boolVal": "false",
            "doubleVal": true,
            "intVal": false,
            "stringVal": true
        ])
        XCTAssert(an.boolVal == false)
        XCTAssert(an.doubleVal == 1)
        XCTAssert(an.intVal == 0)
        XCTAssert(an.stringVal == "true")
        
        an = Model()
        an.decodeFromJson(json: [
            "boolVal": "1",
        ])
        XCTAssert(an.boolVal == true)
        
        an = Model()
        an.decodeFromJson(json: [
            "boolVal": 1,
        ])
        XCTAssert(an.boolVal == true)
    }
    
    @JSONableMacro
    struct NewCustomKeyModel: JSONable {
        var a, b, c, d, e, f, g, h, i: String?
        @JSONableCustomKey("bbb")
        var boolVal: Bool?
        @JSONableCustomKey("ddd")
        var doubleVal: Double?
        @JSONableCustomKey("iii")
        var intVal: Int?
    }
    
    func testNewCustomKey() throws {
        typealias Model = NewCustomKeyModel
        var an = Model()
        an.decodeFromJson(json: [
            "bbb": true,
            "ddd": 3.14,
            "iii": 999,
        ])
        XCTAssert(an.boolVal == true)
        XCTAssert(an.doubleVal == 3.14)
        XCTAssert(an.intVal == 999)
        let json = an.encodeToJson()
        XCTAssert(json["bbb"] as? Bool == true)
        XCTAssert(json["ddd"] as? Double == 3.14)
        XCTAssert(json["iii"] as? Int == 999)
    }
    
    func testPropertyDefineStringKey() throws {
        typealias Model = NewCustomKeyModel
        var an = Model()
        an.decodeFromJson(json: [
            "a": "a",
            "b": "b",
            "c": "c",
        ])
        XCTAssert(an.a == "a")
        XCTAssert(an.b == "b")
        XCTAssert(an.c == "c")
    }
    
    func testPropertyIgnored() throws {
        @JSONableMacro
        struct Person4: JSONable {
            var intVal: Int?
            var stringVal: String?
            @JSONableIgnoreKey
            var ignoreVal: String = "abcde"
        }
        let ppper = Person4(fromJson: [
            "intVal": 999,
            "stringVal": "3.14",
            "ignoreVal": "999",
        ])
        
        XCTAssert(ppper.ignoreVal == "abcde")
    }
}

#endif
