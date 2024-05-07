//
//  File.swift
//  
//
//  Created by zjj on 2024/4/29.
//

import Foundation

/// 来自JSON的值
public typealias JSONValue = Any

extension Array where Element: JSONable {
    public init(jsonArray: [[String: JSONValue]]) {
        self = jsonArray.map{ d in
            var m = Element()
            m.decodeFromJson(json: d)
            return m
        }
    }
}

extension Optional: JSONable where Wrapped: JSONable {
    public init() {
        self = .none
    }
    
    public static var allKeyPathList: [JSONableKeyPathObject<Self>] {
        return []
    }
    
    public mutating func decodeFromJson(json: [String: JSONValue]) {
        var obj = Wrapped()
        obj.decodeFromJson(json: json)
        self = .some(obj)
    }
    
    public func encodeToJson() -> [String: JSONValue] {
        switch self {
        case .none:
            return [:]
        case .some(let somJ):
            return somJ.encodeToJson()
        }
    }
}

public protocol BasicValue { }

extension String: BasicValue { }

extension Int: BasicValue { }
extension Int8: BasicValue {}
extension Int16: BasicValue {}
extension Int32: BasicValue {}
extension Int64: BasicValue {}
extension UInt: BasicValue {}
extension UInt8: BasicValue {}
extension UInt16: BasicValue {}
extension UInt32: BasicValue {}
extension UInt64: BasicValue {}

extension Float: BasicValue { }
extension Double: BasicValue { }

extension Bool: BasicValue { }

extension Optional: BasicValue where Wrapped: BasicValue { }

extension Array: BasicValue where Element: BasicValue { }

extension Dictionary: BasicValue where Key == String, Value == JSONValue { }

public protocol JSONableEnum {
    associatedtype RawValue: BasicValue
    init?(rawValue: RawValue)
    var rawValue: RawValue { get }
}

extension Optional: JSONableEnum where Wrapped: JSONableEnum {
    public typealias RawValue = Optional<Wrapped.RawValue>
    
    public init?(rawValue: RawValue) {
        guard let rawValue = rawValue, let w = Wrapped(rawValue: rawValue) else {
            return nil
        }
        self = .some(w)
    }
    
    public var rawValue: RawValue {
        switch self {
        case .some(let e):
            return e.rawValue
        case .none:
            return nil
        }
    }
}
