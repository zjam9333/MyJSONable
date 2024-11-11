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
}

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

extension JSONableMapper where T == Int {
    static let myFakeIntMapper = JSONableMapper<Int> { v in
        return -100
    } encode: { v in
        return 100
    }
}

do {
    @JSONableMacro
    struct Person5: JSONable {
        var intVal: Int?
        @JSONableCustomMapper("testCustom", mapper: .myFakeIntMapper)
        var customMap: Int = 0
    }
    let ppper2 = Person5(fromJson: [
        "intVal": 999,
        "stringVal": "3.14",
        "ignoreVal": "999",
        "testCustom": 888,
    ])
//    assert(ppper2.customMap == -100)
    let js = ppper2.encodeToJsonString()!
//    assert((js["testCustom"] as? Int) == 100)
    print("test JSONableCustomMapper", ppper2)
    print("json", js)
}
