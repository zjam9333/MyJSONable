//
//  File.swift
//  
//
//  Created by zjj on 2024/5/11.
//

import Foundation
import SwiftSyntax

/// 解析代码结构：class或struct、properties、functions等
struct DeclCheck {
    private let decl: DeclGroupSyntax
    
    var structSyntax: StructDeclSyntax? {
        return decl.as(StructDeclSyntax.self)
    }
    
    var classSyntax: ClassDeclSyntax? {
        return decl.as(ClassDeclSyntax.self)
    }
    
    init(decl: DeclGroupSyntax) {
        self.decl = decl
    }
    
    var typeName: String? {
        let nameToken = structSyntax?.name ?? classSyntax?.name
        switch nameToken?.tokenKind {
        case .identifier(let name):
            return name
        default:
            return nil
        }
    }
    
    var inheritedTypes: Set<String> {
        let inheritanceClause = decl.inheritanceClause
        let types = inheritanceClause?.inheritedTypes
        let toStrings = types?.compactMap { t -> String? in
            let inheritedType = t.type
            // IdentifierTypeSyntax: "Person" for "class Student: Person"
            // MemberTypeSyntax: "Earth.Person" for "class Student: Earth.Person"
            guard let name = inheritedType.as(IdentifierTypeSyntax.self)?.name ?? inheritedType.as(MemberTypeSyntax.self)?.name else {
                return nil
            }
            switch name.tokenKind {
            case .identifier(let idd):
                return idd
            default:
                return nil
            }
        }
        return Set(toStrings ?? [])
    }
    
    var memberProperties: [String] {
        let memberList = decl.memberBlock.members
        let memberProperties = memberList.flatMap { member -> [String] in
            guard let variable = member.decl.as(VariableDeclSyntax.self) else {
                return []
            }
            guard isVarSetableProperty(syntax: variable) else {
                return []
            }
            let patterns = variable.bindings.map(\.pattern)
            let names = patterns.compactMap { $0.as(IdentifierPatternSyntax.self)?.identifier.text }
            return names
        }
        return memberProperties
    }
    
    var functions: [String] {
        let memberList = decl.memberBlock.members
        let funs = memberList.flatMap { member -> [String] in
            guard let fun: FunctionDeclSyntax = member.decl.as(FunctionDeclSyntax.self) else {
                return []
            }
            
            switch fun.name.tokenKind {
            case .identifier(let name):
                return [name]
            default:
                return []
            }
        }
        return funs
    }
    
    private func isVarSetableProperty(syntax: VariableDeclSyntax) -> Bool {
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
    }
}
