# MyJSONable

JSON to Model, Model to JSON

## Implement

通过简单的keyPaths遍历实现property写入

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

print("\nbefor set", String(describing: animal.encodeToJsonString()!), separator: "\n")
animal.decodeFromJson(json: json)

print("\nafter set", String(describing: animal.encodeToJsonString()!), separator: "\n")
```

use `@JSONableMacro` macro to auto generate `allKeyPathList` getter, or write manually

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
static let customKeyPathList: [JSONableKeyPathObject<Animal2>] = [
    .init(name: "cccc", keyPath: \.children2)
    ]
```

### Custom value mapper 自定义类型的转化

mapper `JsonValue <--> ModelValue`

example `var birthday: Date?`

```swift
static let customKeyPathList: [JSONableKeyPathObject<Animal2>] = [
    .init(name: "birthday", keyPath: \.birthday, customGet: { someDate in
        return someDate?.timeIntervalSince1970
    }, customSet: { someI in
        if let interv = someI as? TimeInterval {
            return Date(timeIntervalSince1970: interv)
        }
        return nil
    }),
]
```

### Exclude Keys to JSON 输出Json时排除特定key

example: exclude key `price` while encodeToJSON
```swift
@JSONableMacro
struct Animal_M: JSONable {
    var age: Int = 0
    var name: String = "Cat"
    var price: String = "Value not to JSON"
    
    static let encodeJsonExcludedKeys: Set<PartialKeyPath<Animal2>> = [
        \.price,
    ]
}
```
