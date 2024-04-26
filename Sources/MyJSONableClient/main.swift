import MyJSONable

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
    var jasfS: String {
        get {
            return "b"
        }
        set {
            stringVal = newValue
        }
    }
    
    @JSONableMacro
    struct ChildAnimal2: MyJSONable.JSONable {
        var age2: Int = 0
        var name2: String = ""
        var stringList: [String]?
    }
    
    static var otherFunction: String {
        return "sfd"
    }
    
}

var animal = Animal2()
let json: [String: Any] = [
    "boolVal": true,
    "doubleVal": 3.14,
    "intVal": "314",
    "stringVal": "New Dog",
    "optionalVal": 99,
    "intAnimal": 2,
//    "stringAnimal": nil, 
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
    "children2": [
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
