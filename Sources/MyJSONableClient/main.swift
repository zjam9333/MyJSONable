import MyJSONable
import Foundation

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

let ca = Student(fromJson: [
    "boolVal": 999,
    "doubleVal": "3.14",
    "intVal": "999",
    "stringVal": 1999.99,
    "name": "hello"
])
print(assert(ca.doubleVal == 3.14))
print(assert(ca.name == "hello"))
