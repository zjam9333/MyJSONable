//
//  File.swift
//  
//
//  Created by zjj on 2024/4/29.
//

import Foundation

/// 来自JSON的值
public typealias JSONValue = Any

extension Array where Element: JSONEncodeDecode {
    public init(jsonArray: [[String: JSONValue]]) {
        self = jsonArray.map{ d in
            var m = Element()
            m.decodeFromJson(json: d)
            return m
        }
    }
}

extension Optional: JSONable where Wrapped: JSONEncodeDecode {
    public init() {
        self = .none
    }
    
    public func allKeyPathList() -> [JSONableKeyPathObject] {
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

public struct JSONableMapper<T> {
    let decode: (Any) -> T?
    let encode: (T) -> Any?
    
    public init(decode: @escaping (Any) -> T?, encode: @escaping (T) -> Any?) {
        self.decode = decode
        self.encode = encode
    }
}

extension JSONableMapper where T == Date {
    
    public static let unixTimeStampSecond = JSONableMapper<Date> { any in
        var timeInterval: TimeInterval?
        switch any {
        case let t as TimeInterval:
            timeInterval = t
        default:
            timeInterval = TimeInterval._transform(from: any)
        }
        guard let timeInterval = timeInterval else {
            return nil
        }
        return Date(timeIntervalSince1970: timeInterval)
    } encode: { date in
        return date.timeIntervalSince1970
    }
    
    public static let unixTimeStampMilliSecond = JSONableMapper<Date> { any in
        var timeInterval: TimeInterval?
        switch any {
        case let t as TimeInterval:
            timeInterval = t
        default:
            timeInterval = TimeInterval._transform(from: any)
        }
        guard var timeInterval = timeInterval else {
            return nil
        }
        timeInterval /= 1000
        return Date(timeIntervalSince1970: timeInterval)
    } encode: { date in
        return date.timeIntervalSince1970 * 1000
    }
}
