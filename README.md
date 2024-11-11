# MyJSONable

JSON to Model, Model to JSON

## Version

### 1.2.0?

news:

- 新增宏`JSONableIngoreKey`直接忽略属性的映射，包括encode和decode
- 新增宏`JSONableCustomMapper`替代`customKeyPathList()`方法
- 新增`didFinishDecode`方法

changes:

- `Date`类型必须使用`JSONableDateMapper`或`JSONableIngoreKey`修饰
- 移除`encodeJsonExcludedKeys`实现，推荐使用`JSONableIngoreKey`
- 移除`customKeyPathList()`实现，推荐使用`JSONableCustomMapper`

### 1.1.3

news:

- 新增Date属性转化宏`JSONableDateMapper`，以支持unix时间戳（秒和毫秒）

### 1.1.2

news:

- 新增自定义key宏`JSONableCustomKey`，标记于属性前面

changes & fixed: 

- 修复了连续定义的属性keyPathList代码生成缺少变量，例如`var a, b, c, d: String?`

### 1.1.1

changes:

- `ValueTypeKeyPathProvider`名称标记为废弃
- macro实现去除`ExtensionMacro`协议实现

### 1.1.0

news: 

- 子类继承专用宏`JSONableSubclassMacro`

changes:

- JSONable协议拆分为`KeyPathListProvider & JSONEncodeDecode`
- KeyPathListProvider将原有的`static var allKeyPathList`改为`func allKeyPathList()`
- JSONableKeyPathObject去除了泛型，keyPath需要补全Root类型，例如`\.name`改为`\XXX.name`

issues:

- class继承时，混用父类keyPath和子类keyPath，导致`encodeJsonExcludedKeys`无法正确排除

### 1.0.0

- 基础功能 JSONable + JSONableMacro宏

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
struct Animal: JSONable {
    var boolVal: Bool = false
    var doubleVal: Double = 0
    var intVal: Int = 0
    var stringVal: String = ""
    var child3: [String: Any] = [:]
}

var animal = Animal()
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

```
@JSONableCustomKey("cccc")
var children2: Child?
```

### Custom value mapper 自定义类型的转化

mapper `JsonValue <--> ModelValue`

use macro `JSONableCustomMapper` on property

```swift
@JSONableMacro
struct Person5: JSONable {
    var intVal: Int?
    @JSONableCustomMapper("testCustom", mapper: .myFakeIntMapper)
    var customMap: Int = 0
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

or use new macro `JSONableIgnoreKey`
```
@JSONableMacro
struct Person4: JSONable {
    var intVal: Int?
    var stringVal: String?
    @JSONableIgnoreKey
    var ignoreVal: String = "abcde"
}
```

### Date Mapper 日期转换

example: map unixTimeStamp to Date

```swift
@JSONableMacro
struct DateTest: JSONable {
    @JSONableDateMapper("date1000", mapper: .unixTimeStampMilliSecond)
    var date2: Date? // with custom key "date1000"
    @JSONableDateMapper("date0", mapper: .unixTimeStampSecond)
    var date: Date? // with custom key "date0"
    @JSONableDateMapper(mapper: .unixTimeStampSecond)
    var date3: Date? // with default key "date3" depends on name
}
```

for other mapper, you can add extension to `JSONableMapper where T == Date`

```swift
extension JSONableMapper where T == Date {
    public static let iso8601 = JSONableMapper<Date> { any in
        // return your date
    } encode: { date in
        // return your value
    }
}
```
