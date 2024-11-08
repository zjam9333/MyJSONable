import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(MyJSONableMacros)
import MyJSONableMacros

final class TestMacro: XCTestCase {
    
    func testMacroClass() throws {
        assertMacroExpansion(#"""
            @JSONableMacro
            class ClassAnimal: JSONable {
                var boolVal: Bool?
                var doubleVal: Double?
                var intVal: Int?
                var stringVal: String?
                required init() {}
            }
            """#, expandedSource: #"""
            class ClassAnimal: JSONable {
                var boolVal: Bool?
                var doubleVal: Double?
                var intVal: Int?
                var stringVal: String?
                required init() {}
            
                func allKeyPathList() -> [JSONableKeyPathObject] {
                    return [
                        .init(name: "boolVal", keyPath: \ClassAnimal.boolVal),
                        .init(name: "doubleVal", keyPath: \ClassAnimal.doubleVal),
                        .init(name: "intVal", keyPath: \ClassAnimal.intVal),
                        .init(name: "stringVal", keyPath: \ClassAnimal.stringVal),
                    ]
                }
            }
            """#, macros: ["JSONableMacro": JSONableMacro.self])
    }
    
    func testCustomKeyClass() throws {
        assertMacroExpansion(#"""
            @JSONableMacro
            class ClassAnimal: JSONable {
                var a, b, c, d: Int?
                @JSONableCustomKey("strrrrrr")
                var stringVal: String?
                required init() {}
            }
            """#, expandedSource: #"""
            class ClassAnimal: JSONable {
                var a, b, c, d: Int?
                var stringVal: String?
                required init() {}
            
                func allKeyPathList() -> [JSONableKeyPathObject] {
                    return [
                        .init(name: "a", keyPath: \ClassAnimal.a),
                        .init(name: "b", keyPath: \ClassAnimal.b),
                        .init(name: "c", keyPath: \ClassAnimal.c),
                        .init(name: "d", keyPath: \ClassAnimal.d),
                        .init(name: "strrrrrr", keyPath: \ClassAnimal.stringVal),
                    ]
                }
            }
            """#, macros: ["JSONableMacro": JSONableMacro.self, "JSONableCustomKey": JSONableCustomKeyMacro.self])
    }
    
    func testCustomDate() throws {
        assertMacroExpansion(#"""
            @JSONableMacro
            struct ClassAnimal: JSONable {
                var stringVal: String?
                @JSONableDateMapper("date", mapper: .unixTimeStampSecond)
                var date: Date?
            }
            """#, expandedSource: #"""
            struct ClassAnimal: JSONable {
                var stringVal: String?
                var date: Date?
            
                func allKeyPathList() -> [JSONableKeyPathObject] {
                    return [
                        .init(name: "stringVal", keyPath: \ClassAnimal.stringVal),
                        .init(name: "date", keyPath: \ClassAnimal.date, mapper: .unixTimeStampSecond),
                    ]
                }
            }
            """#, macros: ["JSONableMacro": JSONableMacro.self, "JSONableDateMapper": JSONableCustomDateMacro.self])
    }
    
    func testCustomDateDefaultKey() throws {
        assertMacroExpansion(#"""
            @JSONableMacro
            struct ClassAnimal: JSONable {
                var stringVal: String?
                @JSONableDateMapper(mapper: .unixTimeStampSecond)
                var date: Date?
            }
            """#, expandedSource: #"""
            struct ClassAnimal: JSONable {
                var stringVal: String?
                var date: Date?
            
                func allKeyPathList() -> [JSONableKeyPathObject] {
                    return [
                        .init(name: "stringVal", keyPath: \ClassAnimal.stringVal),
                        .init(name: "date", keyPath: \ClassAnimal.date, mapper: .unixTimeStampSecond),
                    ]
                }
            }
            """#, macros: ["JSONableMacro": JSONableMacro.self, "JSONableDateMapper": JSONableCustomDateMacro.self])
    }
    
    func testMacroVarGetter() throws {
        assertMacroExpansion(#"""
            @JSONableMacro
            struct Animal2: JSONable {
                var boolVal: Bool = false
                var otherFunction: String {
                    return "sfd"
                }
                let strLet = "sfd"
                private var priv_p: String = ""
                var setterGetter: String {
                    get {
                        return "sfd"
                    }
                    set {
                        print("SDF")
                    }
                }
            }
            """#, expandedSource:#"""
            struct Animal2: JSONable {
                var boolVal: Bool = false
                var otherFunction: String {
                    return "sfd"
                }
                let strLet = "sfd"
                private var priv_p: String = ""
                var setterGetter: String {
                    get {
                        return "sfd"
                    }
                    set {
                        print("SDF")
                    }
                }
            
                func allKeyPathList() -> [JSONableKeyPathObject] {
                    return [
                        .init(name: "boolVal", keyPath: \Animal2.boolVal),
                        .init(name: "priv_p", keyPath: \Animal2.priv_p),
                        .init(name: "setterGetter", keyPath: \Animal2.setterGetter),
                    ]
                }
            }
            """#, macros: ["JSONableMacro": JSONableMacro.self])
    }
    
    func testMacroWithJSONable() throws {
        assertMacroExpansion(#"""
            @JSONableMacro
            struct Animal2: JSONable {
                var boolVal: Bool = false
                var doubleVal: Double = 0
                var intVal: Int = 0
                var stringVal: String = ""
                var child3: [String: Any] = [:]
            }
            """#,
            expandedSource: #"""
            struct Animal2: JSONable {
                var boolVal: Bool = false
                var doubleVal: Double = 0
                var intVal: Int = 0
                var stringVal: String = ""
                var child3: [String: Any] = [:]
            
                func allKeyPathList() -> [JSONableKeyPathObject] {
                    return [
                        .init(name: "boolVal", keyPath: \Animal2.boolVal),
                        .init(name: "doubleVal", keyPath: \Animal2.doubleVal),
                        .init(name: "intVal", keyPath: \Animal2.intVal),
                        .init(name: "stringVal", keyPath: \Animal2.stringVal),
                        .init(name: "child3", keyPath: \Animal2.child3),
                    ]
                }
            }
            """#, macros: ["JSONableMacro": JSONableMacro.self]
        )
    }
    
    func testMacroWithCustomKey() throws {
        assertMacroExpansion(#"""
            @JSONableMacro
            struct Animal2: JSONable {
                var boolVal: Bool = false
                var doubleVal: Double = 0
                func customKeyPathList() -> [JSONableKeyPathObject] {
                    return []
                }
                var intVal: Int = 0
                var stringVal: String = ""
                var child3: [String: Any] = [:]
            }
            """#, expandedSource: #"""
            struct Animal2: JSONable {
                var boolVal: Bool = false
                var doubleVal: Double = 0
                func customKeyPathList() -> [JSONableKeyPathObject] {
                    return []
                }
                var intVal: Int = 0
                var stringVal: String = ""
                var child3: [String: Any] = [:]
            
                func allKeyPathList() -> [JSONableKeyPathObject] {
                    return [
                        .init(name: "boolVal", keyPath: \Animal2.boolVal),
                        .init(name: "doubleVal", keyPath: \Animal2.doubleVal),
                        .init(name: "intVal", keyPath: \Animal2.intVal),
                        .init(name: "stringVal", keyPath: \Animal2.stringVal),
                        .init(name: "child3", keyPath: \Animal2.child3),
                    ]
                }
            }
            """#, macros: ["JSONableMacro": JSONableMacro.self]
        )
    }
    
    func testMacroWithClassInherit() throws {
        assertMacroExpansion(#"""
            @JSONableMacro
            class ClassRoot00: AJ1.AJ2.AJ3.JSONable {
                var boolVal: Bool?
                var doubleVal: Double?
                var intVal: Int?
                var stringVal: String?
            
                required init() {}
            }
            @JSONableSubclassMacro
            class ClassLeave33: ClassRoot00, JSONable {
                var name: String?
            }
            """#, expandedSource: #"""
            class ClassRoot00: AJ1.AJ2.AJ3.JSONable {
                var boolVal: Bool?
                var doubleVal: Double?
                var intVal: Int?
                var stringVal: String?
            
                required init() {}
            
                func allKeyPathList() -> [JSONableKeyPathObject] {
                    return [
                        .init(name: "boolVal", keyPath: \ClassRoot00.boolVal),
                        .init(name: "doubleVal", keyPath: \ClassRoot00.doubleVal),
                        .init(name: "intVal", keyPath: \ClassRoot00.intVal),
                        .init(name: "stringVal", keyPath: \ClassRoot00.stringVal),
                    ]
                }
            }
            class ClassLeave33: ClassRoot00, JSONable {
                var name: String?
            
                override func allKeyPathList() -> [JSONableKeyPathObject] {
                    let mines: [JSONableKeyPathObject] = [
                        .init(name: "name", keyPath: \ClassLeave33.name),
                    ]
                    var ours = super.allKeyPathList()
                    ours.append(contentsOf: mines)
                    return ours
                }
            }
            """#, macros: ["JSONableMacro": JSONableMacro.self, "JSONableSubclassMacro": JSONableSubclassMacro.self])
    }
    
    func testMacroIgnoreKey() throws {
        assertMacroExpansion(#"""
            @JSONableMacro
            class ClassAnimal: JSONable {
                var boolVal: Bool?
                @JSONableIgnoreKey
                var doubleVal: Double?
                var intVal: Int?
                @JSONableIgnoreKey
                var stringVal: String = "123"
                required init() {}
            }
            """#, expandedSource: #"""
            class ClassAnimal: JSONable {
                var boolVal: Bool?
                var doubleVal: Double?
                var intVal: Int?
                var stringVal: String = "123"
                required init() {}
            
                func allKeyPathList() -> [JSONableKeyPathObject] {
                    return [
                        .init(name: "boolVal", keyPath: \ClassAnimal.boolVal),
                        .init(name: "intVal", keyPath: \ClassAnimal.intVal),
                    ]
                }
            }
            """#, macros: [
                "JSONableMacro": JSONableMacro.self,
                "JSONableIgnoreKey": JSONableIgnoreKeyMacro.self,
            ])
    }
}
#endif
