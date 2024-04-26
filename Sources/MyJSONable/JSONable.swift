//
//  JSONable.swift
//  SwiftMirrorKeyPath
//
//  Created by zjj on 2024/4/23.
//

import Foundation

public protocol JSONable {
    static var allKeyPathList: [JSONableKeyPathObject<Self>] { get }
    mutating func decodeFromJson(json: [String: Any])
    func encodeToJson() -> [String: Any]
    init()
}

extension JSONable {
    public mutating func decodeFromJson(json: [String: Any]) {
        for kpObj in Self.allKeyPathList {
            let newValue = json[kpObj.name]
            kpObj.setAny(value: newValue, root: &self)
        }
    }
    
    public func encodeToJson() -> [String: Any] {
        var dic = [String: Any]()
        for chi in Self.allKeyPathList {
            let key = chi.name
            let val = self[keyPath: chi.keyPath]
            if let js = val as? any JSONable {
                let subJson = js.encodeToJson()
                dic[key] = subJson
            } else if let arr = val as? [any JSONable] {
                let subArr = arr.map { j in
                    return j.encodeToJson()
                }
                dic[key] = subArr
            } else if let enu = val as? any JSONableEnum {
                dic[key] = enu.rawValue
            } else {
                // 基本数据类型
                // nsnull 在这里？
                dic[key] = val
            }
        }
        return dic
    }
    
    public func encodeToJsonData(options: JSONSerialization.WritingOptions = [.fragmentsAllowed, .prettyPrinted]) -> Data? {
        let dic = encodeToJson()
        if let data = try? JSONSerialization.data(withJSONObject: dic, options: options) {
            return data
        }
        return nil
    }
    
    public func encodeToJsonString(options: JSONSerialization.WritingOptions = [.fragmentsAllowed, .prettyPrinted]) -> String? {
        if let data = encodeToJsonData(options: options),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return nil
    }
}

extension Array where Element: JSONable {
    public init(jsonArray: [[String: Any]]) {
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
    
    public mutating func decodeFromJson(json: [String: Any]) {
        var obj = Wrapped()
        obj.decodeFromJson(json: json)
        self = .some(obj)
    }
    
    public func encodeToJson() -> [String: Any] {
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

extension Float: BasicValue { }
extension Double: BasicValue { }

extension Bool: BasicValue { }

extension Optional: BasicValue where Wrapped: BasicValue { }

extension Array: BasicValue where Element: BasicValue { }

extension Dictionary: BasicValue where Key == String, Value == Any { }

public struct JSONableKeyPathObject<Root> {
    let name: String
    let keyPath: PartialKeyPath<Root>
    
    private var setValue: (Any?, inout Root) -> Void
    
    func setAny(value: Any?, root: inout Root) {
        setValue(value, &root)
    }
    
    private init<Value>(private: Any?, name: String, keyPath: WritableKeyPath<Root, Value>) {
        self.name = name
        self.keyPath = keyPath
        setValue = { valueFromJson, root in
            if valueFromJson is NSNull {
                return
            }
            if let val = valueFromJson as? Value {
                root[keyPath: keyPath] = val
            } else if let tt = Value.self as? _BuiltInBridgeType.Type, let valueFromJson = valueFromJson {
                let some = tt._transform(from: valueFromJson)
                if let val = some as? Value {
                    root[keyPath: keyPath] = val
                }
            }
        }
    }
    
    /// Basic Value: String, Bool, Int, Double.... [Basic Value]
    public init<Value>(name: String, keyPath: WritableKeyPath<Root, Value>) where Value: BasicValue {
        self.init(private: nil, name: name, keyPath: keyPath)
    }
    
    
    /// Enum
    public init<ENUM>(name: String, keyPath: WritableKeyPath<Root, ENUM>) where ENUM: JSONableEnum {
        self.init(private: nil, name: name, keyPath: keyPath)
        let superSetValue = setValue
        setValue = { v, r in
            if let d = v as? ENUM.RawValue {
                let newModel = ENUM(rawValue: d)
                superSetValue(newModel, &r)
            }
        }
    }
    
    /// JSONValue
    public init<JSON>(name: String, keyPath: WritableKeyPath<Root, JSON>) where JSON: JSONable {
        self.init(private: nil, name: name, keyPath: keyPath)
        let superSetValue = setValue
        setValue = { v, r in
            if let d = v as? [String: Any] {
                var newModel = JSON()
                newModel.decodeFromJson(json: d)
                superSetValue(newModel, &r)
            }
        }
    }
    
    /// [JSONValue]
    public init<JSON>(name: String, keyPath: WritableKeyPath<Root, Array<JSON>>) where JSON: JSONable {
        self.init(private: nil, name: name, keyPath: keyPath)
        let superSetValue = setValue
        setValue = { v, r in
            var arr = [JSON]()
            (v as? Array<Any>)?.forEach { d in
                if let d = d as? [String: Any] {
                    var newModel = JSON()
                    newModel.decodeFromJson(json: d)
                    arr.append(newModel)
                }
            }
            superSetValue(arr, &r)
        }
    }
    
    /// [JSONValue]?
    public init<JSON>(name: String, keyPath: WritableKeyPath<Root, Optional<Array<JSON>>>) where JSON: JSONable {
        self.init(private: nil, name: name, keyPath: keyPath)
        let superSetValue = setValue
        setValue = { v, r in
            if let jsonArr = v as? Array<Any> {
                var arr = [JSON]()
                jsonArr.forEach { d in
                    if let d = d as? [String: Any] {
                        var newModel = JSON()
                        newModel.decodeFromJson(json: d)
                        arr.append(newModel)
                    }
                }
                superSetValue(arr, &r)
            }
        }
    }
    
    /// [JSONValue?] [JSONValue]?
    /// 不懂这个结构
    
}

public protocol JSONableEnum {
    associatedtype RawValue: BasicValue
    init?(rawValue: RawValue)
    var rawValue: RawValue { get }
}

extension Optional: JSONableEnum where Wrapped: JSONableEnum {
    public typealias RawValue = Optional<Wrapped.RawValue>
    
    public var rawValue: RawValue {
        switch self {
        case .none:
            return .none
        case .some(let enu):
            return enu.rawValue
        }
    }
    
    public init?(rawValue: RawValue) {
        if let rawValue = rawValue, let en = Wrapped(rawValue: rawValue) {
            self = .some(en)
        } else {
            self = .none
        }
    }
}
