//
//  JSONable.swift
//  SwiftMirrorKeyPath
//
//  Created by zjj on 2024/4/23.
//

import Foundation

public protocol JSONable {
    /// 写入属性必要的列表，可用Macro生成
    static var allKeyPathList: [JSONableKeyPathObject<Self>] { get }
    
    /// 自定义的KeyPathList，可以改写jsonKey，customMap等
    static var customKeyPathList: [JSONableKeyPathObject<Self>] { get }
    mutating func decodeFromJson(json: [String: JSONValue])
    init(fromJson json: [String: JSONValue])
    func encodeToJson() -> [String: JSONValue]
    init()
}

extension JSONable {
    
    public init(fromJson json: [String: JSONValue]) {
        self.init()
        self.decodeFromJson(json: json)
    }
    
    public static var customKeyPathList: [JSONableKeyPathObject<Self>] {
        return []
    }
    
    public mutating func decodeFromJson(json: [String: JSONValue]) {
        for kpObj in Self.allKeyPathList {
            let newValue = json[kpObj.name]
            kpObj.setValue(newValue, &self)
        }
        for kpObj in Self.customKeyPathList {
            let newValue = json[kpObj.name]
            kpObj.setValue(newValue, &self)
        }
    }
    
    public func encodeToJson() -> [String: JSONValue] {
        var json = [String: JSONValue]()
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
            json[key] = chi.getValue(self)
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

public struct JSONableKeyPathObject<Root> {
    
    let name: String
    let keyPath: PartialKeyPath<Root>
    
    let setValue: (JSONValue?, inout Root) -> Void
    
    let getValue: (Root) -> JSONValue?
    
    private init<Value>(private: JSONValue?, name: String, keyPath: WritableKeyPath<Root, Value>, customGet: @escaping (Value) -> JSONValue?, customSet: @escaping (JSONValue) -> Value?) {
        self.name = name
        self.keyPath = keyPath
        
        getValue = { r in
            let oldValue = r[keyPath: keyPath]
            return customGet(oldValue)
        }
        setValue = { v, r in
            if let v = v, let mo = customSet(v) {
                r[keyPath: keyPath] = mo
            }
        }
    }
    
    /// 任意Any转Value的CustomMap方法，customGet必须返回JSON可接受类型
    public init<Value>(name: String, keyPath: WritableKeyPath<Root, Value>, customGet: @escaping (Value) -> JSONValue?, customSet: @escaping (JSONValue) -> Value?) {
        self.init(private: nil, name: name, keyPath: keyPath, customGet: customGet, customSet: customSet)
    }
    
    /// 未实现的类型，默认不转换（用于代码生成能编译通过）
    public init<Value>(name: String, keyPath: WritableKeyPath<Root, Value>) {
        self.init(private: nil, name: name, keyPath: keyPath) { v in
            return nil
        } customSet: { a in
            return nil
        }
    }
    
    /// Basic Value: String, Bool, Int, Double.... [Basic Value]
    public init<Value>(name: String, keyPath: WritableKeyPath<Root, Value>) where Value: BasicValue {
        self.init(private: nil, name: name, keyPath: keyPath) { v in
            return v
        } customSet: { valueFromJson in
            if valueFromJson is NSNull {
                return nil
            }
            if let val = valueFromJson as? Value {
                return val
            } else if let tt = Value.self as? _BuiltInBridgeType.Type {
                let some = tt._transform(from: valueFromJson)
                if let val = some as? Value {
                    return val
                }
            }
            return nil
        }
    }
    
    /// Enum
    public init<EnumType>(name: String, keyPath: WritableKeyPath<Root, EnumType>) where EnumType: JSONableEnum {
        self.init(name: name, keyPath: keyPath) { enu in
            return enu.rawValue
        } customSet: { j in
            if let j = j as? EnumType.RawValue {
                return EnumType(rawValue: j)
            }
            return nil
        }
    }
    
    /// Array<Enum> ？？用这样的？
//    public init<EnumType>(name: String, keyPath: WritableKeyPath<Root, Array<EnumType>>) where EnumType: JSONableCustomMap {
//    }
    
    /// Model
    public init<Model>(name: String, keyPath: WritableKeyPath<Root, Model>) where Model: JSONable {
        self.init(name: name, keyPath: keyPath) { model in
            return model.encodeToJson()
        } customSet: { j in
            if let j = j as? [String: JSONValue] {
                return Model(fromJson: j)
            }
            return nil
        }
    }
    
    /// [Model]
    public init<Model>(name: String, keyPath: WritableKeyPath<Root, Array<Model>>) where Model: JSONable {
        self.init(name: name, keyPath: keyPath) { models in
            return models.map { j in
                return j.encodeToJson()
            }
        } customSet: { json in
            let arr = json as? [[String: JSONValue]] ?? []
            return [Model](jsonArray: arr)
        }
    }
    
    /// [Model]?
    public init<Model>(name: String, keyPath: WritableKeyPath<Root, Optional<Array<Model>>>) where Model: JSONable {
        self.init(name: name, keyPath: keyPath) { models in
            return models?.map { j in
                return j.encodeToJson()
            }
        } customSet: { json in
            return [Model](jsonArray: json as? [[String: JSONValue]] ?? [])
        }
    }
    
    /// [Model?] [Model]?
    /// 不懂这个结构
}
