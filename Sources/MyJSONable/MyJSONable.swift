// The Swift Programming Language
// https://docs.swift.org/swift-book

//@attached(extension)
@attached(member, names: named(init(from:)), named(encode(to:)), arbitrary)
@attached(extension, conformances: Codable)
public macro JSONableMacro() = #externalMacro(module: "MyJSONableMacros", type: "MyJSONableMacro")
