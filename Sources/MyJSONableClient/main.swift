import MyJSONable
import Foundation

enum EnumStringAnimal: String, JSONableEnum {
    case cat = "cat"
    case dog = "dog"
}

enum EnumIntAnimal: Int, JSONableEnum {
    case cat = 1
    case dog = 2
}

@JSONableMacro
struct Animal2: MyJSONable.JSONable {
    var boolVal: Bool = false
    var doubleVal: Double = 0
    var intVal: Int = 0
    var optionalVal: Int?
    var stringVal: String = ""
    private var child2: [String: Any] = [:]
    var child3: ChildAnimal2?
    var children: [ChildAnimal2] = []
    var children2: [ChildAnimal2?] = []
    var stringAnimal: EnumStringAnimal? = .cat
    var intAnimal: EnumIntAnimal = .cat
    var birthday: Date?
    
    var childComputed: String {
        get {
            return stringVal
        }
        set {
            stringVal = newValue
        }
    }
    
    var jasf: String {
        get {
            return "b"
        }
    }
    var keyExcluded: String = "Not to JSON"
    
    static let encodeJsonExcludedKeys: Set<PartialKeyPath<Animal2>> = [
        \.keyExcluded,
    ]
    
    @JSONableMacro
    final class ChildAnimal2 {
        //    static var allKeyPathList: [MyJSONable.JSONableKeyPathObject<ChildAnimal2>] = []
        
        var age2: Int = 0
        var name2: String = ""
        var stringList: [String]?
    }
    
    static var otherFunction: String {
        return "sfd"
    }
    
    static let customKeyPathList: [JSONableKeyPathObject<Animal2>] = [
        .init(name: "cccc", keyPath: \.children2),
        .init(name: "birthday", keyPath: \.birthday, customGet: { someDate in
            return someDate?.timeIntervalSince1970
        }, customSet: { someI in
            if let interv = someI as? TimeInterval {
                return Date(timeIntervalSince1970: interv)
            }
            return nil
        }),
    ]
}


var animal = Animal2()
let json: [String: Any] = [
    "boolVal": true,
    "doubleVal": 3.14,
    "intVal": "314",
    "stringVal": "New Dog",
    "optionalVal": 99,
    "intAnimal": 2,
    "stringAnimal": "dog", 
    "birthday": Date().timeIntervalSince1970,
    "child2": [
        "age2": 100,
        "name2": "New Cow"
    ],
    "child3": [
        "age2": 22,
        "name2": "New 222",
    ],
    "children": [
        [
            "age2": 22,
            "name2": "New 222",
        ],
        [
            "age2": 33,
            "name2": "New 333",
        ],
    ],
    "cccc": [
        [
            "age2": 22,
            "name2": "New 222",
        ],
        [
            "age2": 33,
            "name2": "New 333",
        ],
    ],
]

let kp: KeyPath<Animal2, String> = \Animal2.stringVal

print("\nbefor set", String(describing: animal.encodeToJsonString()!), separator: "\n")
animal.decodeFromJson(json: json)

print("\nafter set", String(describing: animal.encodeToJsonString()!), separator: "\n")
