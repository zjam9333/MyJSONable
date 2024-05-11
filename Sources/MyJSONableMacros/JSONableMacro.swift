import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct JSONableError: CustomStringConvertible, Error {
    public private(set) var description: String
}

public struct JSONableMacro: ExtensionMacro, MemberMacro {
    public static func expansion(of node: AttributeSyntax, attachedTo declaration: some DeclGroupSyntax, providingExtensionsOf type: some TypeSyntaxProtocol, conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext) throws -> [ExtensionDeclSyntax] {
        return []
    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        let macroName = String(describing: Self.self)
        guard let _: DeclGroupSyntax = declaration.as(StructDeclSyntax.self) ?? declaration.as(ClassDeclSyntax.self) else {
            throw JSONableError(description: "macro \(macroName) required class or struct")
        }
        let declCheck = DeclCheck(decl: declaration)
        let requiredInherited = "JSONable"
        guard declCheck.inheritedTypes.contains(requiredInherited) else {
            throw JSONableError(description: "macro \(macroName) required inherite \(requiredInherited)")
        }
        guard let typeName = declCheck.typeName else {
            // 这不可能吧？
            throw JSONableError(description: "Unknown type name ....")
        }
        
        guard declCheck.functions.contains("allKeyPathList") == false else {
            return []
        }
        
        var codes: [String] = declCheck.memberProperties.map { name in
            return ".init(name: \"\(name)\", keyPath: \\\(typeName).\(name)),"
        }
        codes.insert("func allKeyPathList() -> [JSONableKeyPathObject] { return [", at: 0)
        codes.append("]}")
        return [
            DeclSyntax(stringLiteral: codes.joined(separator: "\n")),
        ]
    }
}

public struct JSONableSubclassMacro: ExtensionMacro, MemberMacro {
    public static func expansion(of node: AttributeSyntax, attachedTo declaration: some DeclGroupSyntax, providingExtensionsOf type: some TypeSyntaxProtocol, conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext) throws -> [ExtensionDeclSyntax] {
        return []
    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        let macroName = String(describing: Self.self)
        guard let _: DeclGroupSyntax = declaration.as(ClassDeclSyntax.self) else {
            throw JSONableError(description: "macro \(macroName) required class")
        }
        let declCheck = DeclCheck(decl: declaration)
        guard let typeName = declCheck.typeName else {
            // 这不可能吧？
            throw JSONableError(description: "Unknown type name ....")
        }
        
        guard declCheck.functions.contains("allKeyPathList") == false else {
            return []
        }
        
        var codes: [String] = declCheck.memberProperties.map { name in
            return ".init(name: \"\(name)\", keyPath: \\\(typeName).\(name)),"
        }
        codes.insert(#"""
        override func allKeyPathList() -> [JSONableKeyPathObject] {
            let mines: [JSONableKeyPathObject] = [
        """#, at: 0)
        codes.append(#"""
            ]
            var ours = super.allKeyPathList()
            ours.append(contentsOf: mines)
            return ours
        }
        """#)
        return [
            DeclSyntax(stringLiteral: codes.joined(separator: "\n")),
        ]
    }
}

@main
struct MyJSONablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        JSONableMacro.self,
        JSONableSubclassMacro.self
    ]
}
