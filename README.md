# MyJSONable

JSON to Model, Model to JSON

## Version

### 1.0.0

- 基础功能 JSONable + JSONableMacro宏

### 1.1.0

news: 

- 子类继承专用宏`JSONableSubclassMacro`

changes:

- JSONable协议拆分为`KeyPathListProvider & JSONEncodeDecode`
- KeyPathListProvider将原有的`static var allKeyPathList`改为`func allKeyPathList()`
- JSONableKeyPathObject去除了泛型，keyPath需要补全Root类型，例如`\.name`改为`\XXX.name`

issues:

- class继承时，混用父类keyPath和子类keyPath，导致`encodeJsonExcludedKeys`无法正确排除

### 1.1.1

changes:

- `ValueTypeKeyPathProvider`名称标记为废弃
- macro实现去除`ExtensionMacro`协议实现

## Implement

通过简单的keyPaths遍历实现property写入

Decoding Json values to Model properties via keyPaths

## Install

use swift package manager add this git

## Documentation

### Basic 基础用法

```swift
import MyJSONable

@JSONableMacro
struct Animal_M: JSONable {
    var boolVal: Bool = false
    var doubleVal: Double = 0
    var intVal: Int = 0
    var stringVal: String = ""
    var child3: [String: Any] = [:]
}

var animal = Animal2()
let json: [String: Any] = [
    "boolVal": true,
    "doubleVal": 3.14,
    "intVal": 314,
    "stringVal": "New Dog",
    "child": [
        "age2": 100,
        "name2": "New Cow"
    ],
    "child3": [
        "age2": 22,
        "name2": "New 222",
        "stringList": [
            "a", "b", "c",
        ],
    ],
]

animal.decodeFromJson(json: json)

let jsonString = animal.encodeToJsonString()
```

use `@JSONableMacro` macro to auto generate `allKeyPathList` function, otherwise, write this manually

### class 

must be `final class`

```swift
@JSONableMacro
final class ChildAnimal2: MyJSONable.JSONable {
    var age2: Int = 0
    var name2: String = ""
    var stringList: [String]?
}
```

### class inherit

if your superclass is JSONable, use macro JSONableSubclassMacro

```swift
@JSONableMacro
class Person: JSONable {
    var boolVal: Bool?
    var doubleVal: Double?
    var intVal: Int?
    var stringVal: String?
    
    required init() {
    }
}

@JSONableSubclassMacro
class Student: Person {
    var name: String?
    var id: Int = 0
}
```

### Enum 枚举类型

enum type from string or int

```swift
enum EnumStringAnimal: String, JSONableEnum {
    case cat = "cat"
    case dog = "dog"
}

enum EnumIntAnimal: Int, JSONableEnum {
    case cat = 1
    case dog = 2
}
```

### Custom key name 自定义json的key值

Different key from json
example using key `"cccc"` for property `var children2`

```swift
func customKeyPathList() -> [JSONableKeyPathObject] { 
    return [
        .init(name: "cccc", keyPath: \Animal2.children2)
    ]
}
```

### Custom value mapper 自定义类型的转化

mapper `JsonValue <--> ModelValue`

example `var birthday: Date?`

```swift
func customKeyPathList() -> [JSONableKeyPathObject] { 
    return [
        .init(name: "birthday", keyPath: \Animal2.birthday, customGet: { someDate in
            return someDate?.timeIntervalSince1970
        }, customSet: { someI in
            if let interv = someI as? TimeInterval {
                return Date(timeIntervalSince1970: interv)
            }
            return nil
        }),
    ]
}
```

### Exclude Keys to JSON 输出Json时排除特定key

example: exclude key `price` while encodeToJSON
```swift
@JSONableMacro
struct Animal_M: JSONable {
    var age: Int = 0
    var name: String = "Cat"
    var price: String = "Value not to JSON"
    
    func encodeJsonExcludedKeys() -> Set<AnyKeyPath> {
        return [\Animal_M.price,]
    }
}
```
