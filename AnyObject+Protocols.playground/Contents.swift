//: Playground - noun: a place where people can play

import UIKit
import Pantomime

protocol IName {
    var name: String? {get set}
}

class AName: IName {
    var name: String?

    init(name: String) {
        self.name = name
    }
}

let names: [AName] = [AName.init(name: "One"), AName.init(name: "Two"), AName.init(name: "Three")]

let woraroundNames = names.map() {$0 as AnyObject}

let anyNames = names as [AnyObject]

func toDebugString<T>(x: T) -> String {
    return "overload"
}

