import MyJSONable
import Foundation

@JSONableMacro
class Person: JSONable {
    var intVal: Int?
    var stringVal: String?
    var date: Date = Date()
    
    required init() {
    }
    
    func customKeyPathList() -> [JSONableKeyPathObject] {
        return [
            .init(name: "date", keyPath: \Person.date, customGet: { value in
                return value
            }, customSet: { j in
                return Date()
            })
        ]
    }
}

@JSONableSubclassMacro
class Student: Person {
    var name: String?
    var id: Int = 0
    
    override func customKeyPathList() -> [JSONableKeyPathObject] {
        return [
            .init(name: "date2", keyPath: \Student.date, customGet: { value in
                return value
            }, customSet: { j in
                return Date()
            })
        ]
    }
}

// TODO: 有bug！\Person.date和\Student.date的不一样，导致encodeJson时customKeyPathList无法通过KeyPath的hashValue去重

do {
    var ca = Person()
    ca[keyPath: \Student.date] = Date()
    let a: AnyKeyPath = \Person.date
    let b: AnyKeyPath = \Student.date
    let c: AnyKeyPath = \Student.date
    print(ca.date as Any)
}

let ca = Student(fromJson: [
    "boolVal": 999,
    "doubleVal": "3.14",
    "intVal": "999",
    "stringVal": 1999.99,
    "name": "hello",
    "date": "abcd"
])
print(String(describing: ca))
assert(ca.intVal == 999)
assert(ca.name == "hello")
let toJson = ca.encodeToJson()
assert(toJson["date"] as? Date == nil)
assert(toJson["date2"] as? Date != nil)

let ta = JSONableKeyPathObject(name: "da", keyPath: \Person.date)

@JSONableMacro
struct Person22: JSONable {
    
    var b, c, d: Int?
    @JSONableCustomKey("personName")
    var a: Int?
    
    var intVal: Int?
    var stringVal: String?
    var date: Date = Date()
}
