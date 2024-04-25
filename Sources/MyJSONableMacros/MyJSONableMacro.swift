import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

public struct MyJSONableMacro: ExtensionMacro, MemberMacro {
    public static func expansion(of node: AttributeSyntax,
                                 attachedTo declaration: some DeclGroupSyntax,
                                 providingExtensionsOf type: some TypeSyntaxProtocol,
                                 conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext) throws -> [ExtensionDeclSyntax] {
        return []
    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax]
    {
        
        let propertyContainer = try ModelMemberPropertyContainer(decl: declaration, context: context)
        let propertiesName = propertyContainer.memberProperties
        var codes: [String] = propertiesName.map { name in
            return ".init(name: \"\(name)\", keyPath: \\.\(name)),"
        }
        codes.insert("static var allKeyPathList: [MyJSONable.JSONableKeyPathObject<Self>] { return [", at: 0)
        codes.append("]}")
        return [
            DeclSyntax(stringLiteral: codes.joined(separator: "\n")),
            DeclSyntax("func doSomething() { print(\"adfjoi\") }"),
        ]
    }
}

@main
struct MyJSONablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        MyJSONableMacro.self,
    ]
}


struct ModelMemberPropertyContainer {
    struct AttributeOption: OptionSet {
        let rawValue: UInt
        
        static let open = AttributeOption(rawValue: 1 << 0)
        static let `public` = AttributeOption(rawValue: 1 << 1)
        static let required = AttributeOption(rawValue: 1 << 2)
    }
    
    struct GenConfig {
        let isOverride: Bool
    }
    
    let context: MacroExpansionContext
    fileprivate let decl: DeclGroupSyntax
    private(set) var memberProperties: [String] = []
    
    init(decl: DeclGroupSyntax, context: some MacroExpansionContext) throws {
        self.decl = decl
        self.context = context
        memberProperties = fetchModelMemberProperties()
    }
    
    func fetchModelMemberProperties() -> [String] {
        let memberList = decl.memberBlock.members
        let memberProperties = memberList.flatMap { member -> [String] in
            guard let variable = member.decl.as(VariableDeclSyntax.self), variable.isStoredProperty else {
                return []
            }
            let patterns = variable.bindings.map(\.pattern)
            let names = patterns.compactMap { $0.as(IdentifierPatternSyntax.self)?.identifier.text }
            return names
        }
        return memberProperties
    }
}

extension VariableDeclSyntax {
    /// Determine whether this variable has the syntax of a stored property.
    ///
    /// This syntactic check cannot account for semantic adjustments due to,
    /// e.g., accessor macros or property wrappers.
    var isStoredProperty: Bool {
        if modifiers.compactMap({ $0.as(DeclModifierSyntax.self) }).contains(where: { $0.name.text == "static" }) {
            return false
        }
        if bindings.count < 1 {
            return false
        }
        let binding = bindings.last!
        switch binding.accessorBlock?.accessors {
        case .none:
            return true
        case let .accessors(o):
            for accessor in o {
                switch accessor.accessorSpecifier.tokenKind {
                case .keyword(.willSet), .keyword(.didSet):
                    // Observers can occur on a stored property.
                    break
                default:
                    // Other accessors make it a computed property.
                    return false
                }
            }
            return true
        case .getter:
            return false
        }
    }
}
