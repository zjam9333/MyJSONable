// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(member, names: arbitrary)
public macro JSONableMacro() = #externalMacro(module: "MyJSONableMacros", type: "JSONableMacro")

@attached(member, names: arbitrary)
public macro JSONableSubclassMacro() = #externalMacro(module: "MyJSONableMacros", type: "JSONableSubclassMacro")

@attached(peer)
public macro JSONableCustomKey(_ key: String) = #externalMacro(module: "MyJSONableMacros", type: "JSONableCustomKeyMacro")
