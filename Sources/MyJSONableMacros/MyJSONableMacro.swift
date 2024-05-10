import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

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
        
        let propertyContainer = try ModelMemberPropertyContainer(decl: declaration)
        let propertiesName = propertyContainer.memberProperties
        let typeName = propertyContainer.name ?? "Self"
        var codes: [String] = propertiesName.map { name in
            return ".init(name: \"\(name)\", keyPath: \\\(typeName).\(name)),"
        }
//        codes.insert("static var allKeyPathList: [MyJSONable.JSONableKeyPathObject<Self>] { return [", at: 0)
//        codes.append("]}")
        
        // 用let比之前的var getter快很多，省略了重复初始化数组的时间
        codes.insert("func allKeyPathList() -> [MyJSONable.JSONableKeyPathObject] { return [", at: 0)
        codes.append("]}")
        return [
            DeclSyntax(stringLiteral: codes.joined(separator: "\n")),
        ]
    }
}

@main
struct MyJSONablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        MyJSONableMacro.self,
    ]
}

struct ModelMemberPropertyContainer {
    private let decl: DeclGroupSyntax
    private(set) var name: String?
    private(set) var memberProperties: [String] = []
    
    init(decl: DeclGroupSyntax) throws {
        self.decl = decl
        memberProperties = fetchModelMemberProperties()
        name = typeName()
    }
    
    private func typeName() -> String? {
        var token: TokenSyntax?
        if let decl = decl.as(StructDeclSyntax.self) {
            token = decl.name
        } else if let decl = decl.as(ClassDeclSyntax.self) {
            token = decl.name
        }
        switch token?.tokenKind {        
        case .none:
            break
        case .identifier(let name):
            return name
        default: 
            break
        }
        return nil
    }
    
    private func fetchModelMemberProperties() -> [String] {
        let memberList = decl.memberBlock.members
        let memberProperties = memberList.flatMap { member -> [String] in
            guard let variable = member.decl.as(VariableDeclSyntax.self) else {
                return []
            }
            guard isMyProperty(syntax: variable) else {
                return []
            }
            let patterns = variable.bindings.map(\.pattern)
            let names = patterns.compactMap { $0.as(IdentifierPatternSyntax.self)?.identifier.text }
            return names
        }
        return memberProperties
    }
    
    func isMyProperty(syntax: VariableDeclSyntax) -> Bool {
        // 非 static
        let isStatic = syntax.modifiers.compactMap {
            $0.as(DeclModifierSyntax.self)
        }.contains {
            $0.name.text == "static"
        }
        guard isStatic == false else {
            return false
        }
        // var 属性
        guard case .keyword(.var) = syntax.bindingSpecifier.tokenKind else {
            return false
        }
        // 可以set
        let isCanSetProperty = syntax.bindings.contains { patt in
            switch patt.accessorBlock?.accessors {
            case .none:
                return true
            case .accessors(let s):
                for accessor in s {
                    switch accessor.accessorSpecifier.tokenKind {
                    case .keyword(.set), .keyword(.didSet), .keyword(.willSet):
                        return true
                    default:
                        continue
                    }
                }
            default:
                break
            }
            return false;
        }
        guard isCanSetProperty else {
            return false
        }
        return true
        /*
        guard let binding = syntax.bindings.last else {
            return false
        }
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
         */
    }
}
