// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(member, names: arbitrary)
public macro JSONableMacro() = #externalMacro(module: "MyJSONableMacros", type: "JSONableMacro")

@attached(member, names: arbitrary)
public macro JSONableSubclassMacro() = #externalMacro(module: "MyJSONableMacros", type: "JSONableSubclassMacro")
