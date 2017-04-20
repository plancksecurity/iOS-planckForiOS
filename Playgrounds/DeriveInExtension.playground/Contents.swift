//: Playground - noun: a place where people can play

import UIKit


class NotObjc {
    let someString: String
    let someObjc = NSCache<NSString, NSString>()

    init(someString: String) {
        self.someString = someString
    }
}

extension NotObjc: CustomStringConvertible {
    var description: String {
        return "<NotObjc someString \(someString)>"
    }
}

class Objc: NSObject {
    let someString: String

    init(someString: String) {
        self.someString = someString
    }
}

NotObjc(someString: "1").description
Objc(someString: "1").description
