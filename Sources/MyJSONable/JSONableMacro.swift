// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

@attached(member, names: arbitrary)
public macro JSONableMacro() = #externalMacro(module: "MyJSONableMacros", type: "JSONableMacro")

@attached(member, names: arbitrary)
public macro JSONableSubclassMacro() = #externalMacro(module: "MyJSONableMacros", type: "JSONableSubclassMacro")

@attached(peer)
public macro JSONableCustomKey(_ key: String) = #externalMacro(module: "MyJSONableMacros", type: "JSONableCustomKeyMacro")

@attached(peer)
public macro JSONableDateMapper(_ key: String, mapper: JSONableMapper<Date>) = #externalMacro(module: "MyJSONableMacros", type: "JSONableCustomDateMacro")
