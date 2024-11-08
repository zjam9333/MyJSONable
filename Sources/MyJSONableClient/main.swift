import MyJSONable
import Foundation

@JSONableMacro
class Person: JSONable {
    var intVal: Int?
    var stringVal: String?
    @JSONableDateMapper(mapper: .unixTimeStampSecond)
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
//    var ca = Person()
//    ca[keyPath: \Student.date] = Date()
//    let a: AnyKeyPath = \Person.date
//    let b: AnyKeyPath = \Student.date
//    let c: AnyKeyPath = \Student.date
//    print(ca.date as Any)
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

@JSONableMacro
struct Person22: JSONable {
    
    var b, c, d: Int?
    @JSONableCustomKey("personName")
    var a: Int?
    
    var intVal: Int?
    var stringVal: String?
    @JSONableDateMapper(mapper: .unixTimeStampSecond)
    var date: Date = Date()
}

do {
    @JSONableMacro
    struct DateTest: JSONable {
        @JSONableDateMapper("date1000", mapper: .unixTimeStampMilliSecond)
        var date2: Date?
        @JSONableDateMapper("date", mapper: .unixTimeStampSecond)
        var date: Date?
        @JSONableDateMapper(mapper: .unixTimeStampSecond)
        var date3: Date?
    }
    let caDateTest = DateTest(fromJson: [
        "boolVal": 999,
        "doubleVal": "3.14",
        "intVal": "999",
        "date": Date().timeIntervalSince1970,
        "date1000": Date().timeIntervalSince1970 * 1000
    ])
    let toJsonMpDateTest = caDateTest.encodeToJson()
    print(toJsonMpDateTest)
    let toJsonDateTest = caDateTest.encodeToJsonString()!
    //print(toJson["date"] as! Double)
    //    assert((toJson["date"] as? Double) == 12345)
    print(toJsonDateTest)
}

do {
    @JSONableMacro
    struct Person4: JSONable {
        var intVal: Int?
        var stringVal: String?
        @JSONableIgnoreKey
        var ignoreVal: String = "abcde"
        
        func didFinishDecode() {
            print("didFinishDecode wow nice !")
        }
    }
    let ppper = Person4(fromJson: [
        "intVal": 999,
        "stringVal": "3.14",
        "ignoreVal": "999",
    ])
    
    assert(ppper.ignoreVal == "abcde")
}
