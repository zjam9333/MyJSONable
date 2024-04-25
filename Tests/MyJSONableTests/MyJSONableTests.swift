import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(MyJSONableMacros)
import MyJSONableMacros

let testMacros: [String: Macro.Type] = [
    "stringify": StringifyMacro.self,
]
#endif

final class MyJSONableTests: XCTestCase {
    func testMacro() throws {
        #if canImport(MyJSONableMacros)
        assertMacroExpansion(
            """
            #stringify(a + b)
            """,
            expandedSource: """
            (a + b, "a + b")
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacroWithStringLiteral() throws {
        #if canImport(MyJSONableMacros)
        assertMacroExpansion(
            #"""
            #stringify("Hello, \(name)")
            """#,
            expandedSource: #"""
            ("Hello, \(name)", #""Hello, \(name)""#)
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    
    func testMacroWithJSONable() throws {
#if canImport(MyJSONableMacros)
        assertMacroExpansion(
            #"""
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
            ("Hello, \(name)", #""Hello, \(name)""#)
            """#,
            macros: ["JSONableMacro": MyJSONableMacro.self]
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
}
