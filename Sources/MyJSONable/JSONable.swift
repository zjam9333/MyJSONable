//
//  JSONable.swift
//  SwiftMirrorKeyPath
//
//  Created by zjj on 2024/4/23.
//

import Foundation

public typealias JSONable = KeyPathListProvider & JSONEncodeDecode

/// 兼容旧版协议名称，新名称为KeyPathListProvider
@available(*, deprecated, message: "Use KeyPathListProvider instead.")
public typealias ValueTypeKeyPathProvider = KeyPathListProvider

public protocol JSONEncodeDecode {
    mutating func decodeFromJson(json: [String: JSONValue])
    init(fromJson json: [String: JSONValue])
    func encodeToJson() -> [String: JSONValue]
    init()
}

extension JSONEncodeDecode {
    
    public init(fromJson json: [String: JSONValue]) {
        self.init()
        self.decodeFromJson(json: json)
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

public protocol KeyPathListProvider {
    /// 写入属性必要的列表，可用Macro生成
    func allKeyPathList() -> [JSONableKeyPathObject]
}

extension KeyPathListProvider where Self: JSONEncodeDecode {
    
    public mutating func decodeFromJson(json: [String: JSONValue]) {
        for kpObj in allKeyPathList() {
            self = kpObj.setValue(json[kpObj.name], self) as? Self ?? self
        }
    }
    
    public func encodeToJson() -> [String: JSONValue] {
        var json = [String: JSONValue]()
        var allKeyPathDict: [AnyKeyPath: JSONableKeyPathObject] = [:]
        for kpObj in allKeyPathList() {
            allKeyPathDict[kpObj.keyPath] = kpObj
        }
        for keyvale in allKeyPathDict {
            let (_, chi) = keyvale
            let key = chi.name
            json[key] = chi.getValue(self)
        }
        return json
    }
}

public struct JSONableKeyPathObject {
    
    let name: String
    let keyPath: AnyKeyPath
    
    let setValue: (JSONValue?, Any) -> Any
    
    let getValue: (Any) -> JSONValue?
    
    private init<Root, Value>(private: JSONValue?, name: String, keyPath: WritableKeyPath<Root, Value>, customGet: @escaping (Value) -> JSONValue?, customSet: @escaping (JSONValue) -> Value?) {
        self.name = name
        self.keyPath = keyPath
        
        getValue = { r in
            guard let r = r as? Root else {
                return nil
            }
            let oldValue = r[keyPath: keyPath]
            return customGet(oldValue)
        }
        setValue = { v, r in
            guard let v = v else {
                return r
            } 
            guard var r = r as? Root else {
                return r
            }
            guard let mo = customSet(v) else {
                return r
            }
            r[keyPath: keyPath] = mo
            return r
        }
    }
    
    /// 任意Any转Value的CustomMap方法，customGet必须返回JSON可接受类型
    public init<Root, Value>(name: String, keyPath: WritableKeyPath<Root, Value>, customGet: @escaping (Value) -> JSONValue?, customSet: @escaping (JSONValue) -> Value?) {
        self.init(private: nil, name: name, keyPath: keyPath, customGet: customGet, customSet: customSet)
    }
    
    /// Basic Value: String, Bool, Int, Double.... [Basic Value]
    public init<Root, Value>(name: String, keyPath: WritableKeyPath<Root, Value>) where Value: BasicValue {
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
    public init<Root, EnumType>(name: String, keyPath: WritableKeyPath<Root, EnumType>) where EnumType: JSONableEnum {
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
    public init<Root, Model>(name: String, keyPath: WritableKeyPath<Root, Model>) where Model: JSONEncodeDecode {
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
    public init<Root, Model>(name: String, keyPath: WritableKeyPath<Root, Array<Model>>) where Model: JSONEncodeDecode {
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
    public init<Root, Model>(name: String, keyPath: WritableKeyPath<Root, Optional<Array<Model>>>) where Model: JSONEncodeDecode {
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
    
    /// Any Mapper with Value
    public init<Root, Value>(name: String, keyPath: WritableKeyPath<Root, Value>, mapper: JSONableMapper<Value>) {
        self.init(name: name, keyPath: keyPath) { model in
            return mapper.encode(model)
        } customSet: { json in
            return mapper.decode(json)
        }
    }
    
    /// Any Mapper with Value?
    public init<Root, Value>(name: String, keyPath: WritableKeyPath<Root, Value?>, mapper: JSONableMapper<Value>) {
        self.init(name: name, keyPath: keyPath) { model in
            guard let model = model else {
                return nil
            }
            return mapper.encode(model)
        } customSet: { json in
            return mapper.decode(json)
        }
    }
}
