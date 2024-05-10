//
//  File.swift
//  
//
//  Created by zjj on 2024/5/10.
//

import Foundation


protocol SomeSelfProtocol {
    associatedtype Roooot = Self
    func returnSelfKeyPaths() -> [AnyKeyPath]
    init()
}

class A: SomeSelfProtocol {
    var a = "heello A"
    required init() {
        
    }
    static func returnSelfStatic() -> Self {
        return Self()
    }
    func returnSelf() -> Self {
        return self
    }
    
    func returnSelfKeyPaths() -> [AnyKeyPath] {
        return [\A.a]
    }
    
}

class B: A {
    var b = "hello B"
    
    typealias Roooot = A
    func returnSelfKeyPath() -> [AnyKeyPath] {
        var supa = super.returnSelfKeyPaths()
        
        supa.append(\B.b)
        return supa
    }
    
}

enum ClassTest {
    static func test() {
        let a = A()
        let asf = a.returnSelf()
        
        let b = B()
        let bsf = b.returnSelf()
        let kp = b.returnSelfKeyPath()
        print(kp)
    }
}
