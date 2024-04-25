# MyJSONable

JSON to Model, Model to JSON

## Install

swift package manager

## Documentation

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
