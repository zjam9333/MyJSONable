import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct JSONableError: CustomStringConvertible, Error {
    public private(set) var description: String
}

public struct JSONableMacro: MemberMacro {
    
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
        
        var codes: [String] = declCheck.memberProperties.flatMap { name in
            return name.customKeyPathInitCode(typeName: typeName)
        }
        codes.insert("func allKeyPathList() -> [JSONableKeyPathObject] { return [", at: 0)
        codes.append("]}")
        return [
            DeclSyntax(stringLiteral: codes.joined(separator: "\n")),
        ]
    }
}

public struct JSONableSubclassMacro: MemberMacro {
    
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
        
        var codes: [String] = declCheck.memberProperties.flatMap { name in
            return name.customKeyPathInitCode(typeName: typeName)
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

public protocol DefaultPeerPropertyMacroProtocol: PeerMacro {
    
}

extension DefaultPeerPropertyMacroProtocol {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard let variable = declaration.as(VariableDeclSyntax.self) else {
            throw JSONableError(description: "attached on properties only")
        }
        let property = PropertyStruct(variable: variable, igoreAttribute: true)
        if property.names.count > 1 {
            throw JSONableError(description: "required 1 property name only, found \(property.names.count), write variable code separately")
        }
        return []
    }
}

public struct JSONableCustomKeyMacro: DefaultPeerPropertyMacroProtocol {
}

public struct JSONableIgnoreKeyMacro: DefaultPeerPropertyMacroProtocol {
}

public struct JSONableCustomMapperMacro: DefaultPeerPropertyMacroProtocol {
}

public struct JSONableCustomDateMacro: DefaultPeerPropertyMacroProtocol {
}

// 这里的宏名称是实际应用的名称，有没有办法不这样写死？
private enum MacroPeerName: String {
    case customKey = "JSONableCustomKey"
    case dateMapper = "JSONableDateMapper"
    case customMapper = "JSONableCustomMapper"
    case ignoreKey = "JSONableIgnoreKey"
}

extension PropertyStruct {
    // 根据property头部的宏，生成不同的映射方法
    func customKeyPathInitCode(typeName: String) -> [String] {
        return names.map { name in
            var customKey = name
            
            // 兼容以下两个宏
            // JSONableCustomKey(_ key: String)
            // JSONableDateMapper(_ key: String? = nil, mapper: JSONableMapper<Date>)
            
            let firstJSONableCustomAttr = attributes.first { attr in
                return MacroPeerName(rawValue: attr.name) != nil
            }
            if let attr = firstJSONableCustomAttr, let firstArg = attr.arguments.first, firstArg.label == nil, firstArg.expression.isEmpty == false {
                // JSONableCustomKey and JSONableDateMapper use non-labeled arg as JSON key
                customKey = firstArg.expression
            }
            
            switch MacroPeerName(rawValue: firstJSONableCustomAttr?.name ?? "") {
            case .dateMapper, .customMapper:
                let mapperArg = firstJSONableCustomAttr?.arguments.first { arg in
                    return arg.label == "mapper"
                }
                if let mapperArg = mapperArg {
                    return ".init(name: \"\(customKey)\", keyPath: \\\(typeName).\(name), mapper: \(mapperArg.expression)),"
                }
            case .ignoreKey:
                return "" // 忽略key直接不返回映射关系
            default:
                break
            }
            return ".init(name: \"\(customKey)\", keyPath: \\\(typeName).\(name)),"
        }
        .filter { code in
            return code.isEmpty == false
        }
    }
}

@main
struct MyJSONablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        JSONableMacro.self,
        JSONableSubclassMacro.self,
        JSONableCustomKeyMacro.self,
        JSONableCustomMapperMacro.self,
        JSONableCustomDateMacro.self,
        JSONableIgnoreKeyMacro.self,
    ]
}
