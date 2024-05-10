import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(MyJSONableMacros)
import MyJSONableMacros

final class MyJSONableTests: XCTestCase {
    
    
    func testMacroClass() throws {
        assertMacroExpansion(#"""
            @JSONableMacro
            final class ChildAnimal2: MyJSONable.JSONable {
                var age2: Int = 0
                var name2: String = ""
                var stringList: [String]?
            }
            """#, expandedSource: #"""
            final class ChildAnimal2: MyJSONable.JSONable {
                var age2: Int = 0
                var name2: String = ""
                var stringList: [String]?
            
                func allKeyPathList() -> [MyJSONable.JSONableKeyPathObject] {
                    return [
                        .init(name: "age2", keyPath: \ChildAnimal2.age2),
                        .init(name: "name2", keyPath: \ChildAnimal2.name2),
                        .init(name: "stringList", keyPath: \ChildAnimal2.stringList),
                    ]
                }
            }
            """#, macros: ["JSONableMacro": MyJSONableMacro.self])
    }
    
    func testMacroVarGetter() throws {
        assertMacroExpansion(#"""
            @JSONableMacro
            struct Animal2: MyJSONable.JSONable {
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
            """#,
        expandedSource:#"""
            struct Animal2: MyJSONable.JSONable {
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
            
                func allKeyPathList() -> [MyJSONable.JSONableKeyPathObject] {
                    return [
                        .init(name: "boolVal", keyPath: \Animal2.boolVal),
                        .init(name: "priv_p", keyPath: \Animal2.priv_p),
                        .init(name: "setterGetter", keyPath: \Animal2.setterGetter),
                    ]
                }
            }
            """#,
        macros: ["JSONableMacro": MyJSONableMacro.self])
    }
    
    func testMacroWithJSONable() throws {
        assertMacroExpansion(#"""
            @JSONableMacro
            struct Animal2: MyJSONable.JSONable {
                var boolVal: Bool = false
                var doubleVal: Double = 0
                var intVal: Int = 0
                var stringVal: String = ""
                var child3: [String: Any] = [:]
            }
            """#,
            expandedSource: #"""
            struct Animal2: MyJSONable.JSONable {
                var boolVal: Bool = false
                var doubleVal: Double = 0
                var intVal: Int = 0
                var stringVal: String = ""
                var child3: [String: Any] = [:]
            
                func allKeyPathList() -> [MyJSONable.JSONableKeyPathObject] {
                    return [
                        .init(name: "boolVal", keyPath: \Animal2.boolVal),
                        .init(name: "doubleVal", keyPath: \Animal2.doubleVal),
                        .init(name: "intVal", keyPath: \Animal2.intVal),
                        .init(name: "stringVal", keyPath: \Animal2.stringVal),
                        .init(name: "child3", keyPath: \Animal2.child3),
                    ]
                }
            }
            """#,
            macros: ["JSONableMacro": MyJSONableMacro.self]
        )
    }
    
    func testMacroWithCustomKey() throws {
        assertMacroExpansion(#"""
            @JSONableMacro
            struct Animal2: MyJSONable.JSONable {
                var boolVal: Bool = false
                var doubleVal: Double = 0
                func customKeyPathList() -> [MyJSONable.JSONableKeyPathObject] {
                    return []
                }
                var intVal: Int = 0
                var stringVal: String = ""
                var child3: [String: Any] = [:]
            }
            """#,
                             expandedSource: #"""
            struct Animal2: MyJSONable.JSONable {
                var boolVal: Bool = false
                var doubleVal: Double = 0
                func customKeyPathList() -> [MyJSONable.JSONableKeyPathObject] {
                    return []
                }
                var intVal: Int = 0
                var stringVal: String = ""
                var child3: [String: Any] = [:]
            
                func allKeyPathList() -> [MyJSONable.JSONableKeyPathObject] {
                    return [
                        .init(name: "boolVal", keyPath: \Animal2.boolVal),
                        .init(name: "doubleVal", keyPath: \Animal2.doubleVal),
                        .init(name: "intVal", keyPath: \Animal2.intVal),
                        .init(name: "stringVal", keyPath: \Animal2.stringVal),
                        .init(name: "child3", keyPath: \Animal2.child3),
                    ]
                }
            }
            """#,
                             macros: ["JSONableMacro": MyJSONableMacro.self]
        )
    }
}
#endif
