import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(MyJSONableMacros)
import MyJSONableMacros
#endif

final class MyJSONableTests: XCTestCase {
    
#if canImport(MyJSONableMacros)
    
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
            
                static let allKeyPathList: [MyJSONable.JSONableKeyPathObject<ChildAnimal2>] = [
                    .init(name: "age2", keyPath: \.age2),
                    .init(name: "name2", keyPath: \.name2),
                    .init(name: "stringList", keyPath: \.stringList),
                ]
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
            
                static let allKeyPathList: [MyJSONable.JSONableKeyPathObject<Animal2>] = [
                    .init(name: "boolVal", keyPath: \.boolVal),
                    .init(name: "priv_p", keyPath: \.priv_p),
                    .init(name: "setterGetter", keyPath: \.setterGetter),
                ]
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
            
                static let allKeyPathList: [MyJSONable.JSONableKeyPathObject<Animal2>] = [
                    .init(name: "boolVal", keyPath: \.boolVal),
                    .init(name: "doubleVal", keyPath: \.doubleVal),
                    .init(name: "intVal", keyPath: \.intVal),
                    .init(name: "stringVal", keyPath: \.stringVal),
                    .init(name: "child3", keyPath: \.child3),
                ]
            }
            """#,
            macros: ["JSONableMacro": MyJSONableMacro.self]
        )
    }
    
    #endif
}
