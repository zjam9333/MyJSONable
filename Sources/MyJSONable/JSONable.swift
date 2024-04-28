//
//  JSONable.swift
//  SwiftMirrorKeyPath
//
//  Created by zjj on 2024/4/23.
//

import Foundation

public protocol JSONable {
    static var allKeyPathList: [JSONableKeyPathObject<Self>] { get }
    
    /// 自定义的KeyPathList，可以改写jsonKey，customMap等
    static var customKeyPathList: [JSONableKeyPathObject<Self>] { get }
    mutating func decodeFromJson(json: [String: Any])
    func encodeToJson() -> [String: Any]
    init()
}

extension JSONable {
    public static var customKeyPathList: [JSONableKeyPathObject<Self>] {
        return []
    }
    
    public mutating func decodeFromJson(json: [String: Any]) {
        for kpObj in Self.allKeyPathList {
            let newValue = json[kpObj.name]
            kpObj.setAny(value: newValue, root: &self)
        }
        for kpObj in Self.customKeyPathList {
            let newValue = json[kpObj.name]
            kpObj.setAny(value: newValue, root: &self)
        }
    }
    
    public func encodeToJson() -> [String: Any] {
        var json = [String: Any]()
        var allKeyPathDict: [AnyHashable: JSONableKeyPathObject<Self>] = [:]
        for kpObj in Self.allKeyPathList {
            allKeyPathDict[kpObj.keyPath] = kpObj
        }
        for kpObj in Self.customKeyPathList {
            // custom的keyPath覆盖默认的allKeyPath
            allKeyPathDict[kpObj.keyPath] = kpObj
        }
        for chi in allKeyPathDict.values {
            let key = chi.name
            json[key] = chi.getAny(root: self)
        }
        return json
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
    
//    private let originalSetValue: (Any?, inout Root) -> Void
    private var setValue: (Any?, inout Root) -> Void
    
    func setAny(value: Any?, root: inout Root) {
        setValue(value, &root)
    }
//    private let originalGetValue: (Root) -> Any?
    private var getValue: (Root) -> Any?
    
    func getAny(root: Root) -> Any? {
        return getValue(root)
    }
    
    private init<Value>(private: Any?, name: String, keyPath: WritableKeyPath<Root, Value>, customGet: ((Value) -> Any?)?, customSet: ((Any) -> Value?)?) {
        self.name = name
        self.keyPath = keyPath
        
        let originalSetValue: (Value, inout Root) -> Void = { v, r in
            r[keyPath: keyPath] = v
        }
        
        let originalGetValue: (Root) -> Value = { r in
            return r[keyPath: keyPath]
        }
        
        if let customGet = customGet {
            getValue = { r in
                let oldValue = originalGetValue(r)
                return customGet(oldValue)
            }
        } else {
            getValue = { r in
                let val = originalGetValue(r)
                if let js = val as? any JSONable {
                    return js.encodeToJson()
                    
                } else if let arr = val as? [any JSONable] {
                    return arr.map { j in
                        return j.encodeToJson()
                    }
                } else if let enu = val as? (any JSONableCustomMap) {
                    return enu.modelToJSONType()
                } else {
                    // 基本数据类型
                    // nsnull 在这里？
                    return val
                }
            }
        }
        if let customSet = customSet {
            setValue = { v, r in
                if let v = v, let mo = customSet(v) {
                    originalSetValue(mo, &r)
                }
            }
        } else {
            setValue = { valueFromJson, root in
                if valueFromJson is NSNull {
                    return
                }
                if let val = valueFromJson as? Value {
                    originalSetValue(val, &root)
                } else if let tt = Value.self as? _BuiltInBridgeType.Type, let valueFromJson = valueFromJson {
                    let some = tt._transform(from: valueFromJson)
                    if let val = some as? Value {
                        originalSetValue(val, &root)
                    }
                }
            }
        }
    }
    
    /// 未实现的类型，默认不转换
    public init<Value>(name: String, keyPath: WritableKeyPath<Root, Value>) {
        self.init(private: nil, name: name, keyPath: keyPath) { v in
            return nil
        } customSet: { a in
            return nil
        }
    }
    
    /// 任意Any转Valye的CustomMap方法
    public init<Value>(name: String, keyPath: WritableKeyPath<Root, Value>, customGet: @escaping (Value) -> Any?, customSet: @escaping (Any) -> Value) {
        self.init(private: nil, name: name, keyPath: keyPath, customGet: customGet, customSet: customSet)
    }
    
    /// Basic Value: String, Bool, Int, Double.... [Basic Value]
    public init<Value>(name: String, keyPath: WritableKeyPath<Root, Value>) where Value: BasicValue {
        self.init(private: nil, name: name, keyPath: keyPath, customGet: nil, customSet: nil)
    }
    
    /// Enum
    public init<CustomMap>(name: String, keyPath: WritableKeyPath<Root, CustomMap>) where CustomMap: JSONableCustomMap {
        self.init(private: nil, name: name, keyPath: keyPath, customGet: nil, customSet: nil)
        let superSetValue = setValue
        setValue = { v, r in
            if let d = v as? CustomMap.JSONType {
                let newModel = CustomMap(rawValue: d)
                superSetValue(newModel, &r)
            }
        }
    }
    
    /// JSONValue
    public init<JSON>(name: String, keyPath: WritableKeyPath<Root, JSON>) where JSON: JSONable {
        self.init(private: nil, name: name, keyPath: keyPath, customGet: nil, customSet: nil)
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
        self.init(private: nil, name: name, keyPath: keyPath, customGet: nil, customSet: nil)
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
        self.init(private: nil, name: name, keyPath: keyPath, customGet: nil, customSet: nil)
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

public protocol JSONableCustomMap {
    associatedtype JSONType
    typealias ModelType = Self
    func modelToJSONType() -> JSONType?
    init?(rawValue: JSONType)
}

public protocol JSONableEnum: JSONableCustomMap where JSONType == RawValue {
    associatedtype RawValue: BasicValue
    init?(rawValue: RawValue)
    var rawValue: RawValue { get }
}

extension JSONableEnum {
    public func modelToJSONType() -> RawValue? {
        return rawValue
    }
}

extension Optional: JSONableCustomMap where Wrapped: JSONableCustomMap {
    public typealias JSONType = Wrapped.JSONType
    
    public init?(rawValue: JSONType) {
        guard let w = Wrapped(rawValue: rawValue) else {
            return nil
        }
        self = .some(w)
    }
    
    public func modelToJSONType() -> JSONType? {
        switch self {
        case .none:
            return nil
        case .some(let jj):
            return jj.modelToJSONType()
        }
    }
}
