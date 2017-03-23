//: Playground - noun: a place where people can play

import UIKit

let regex = try NSRegularExpression(pattern: "<img src=\"file:///Attachment(_\\d+)?.png\" alt=\"Attachment(_\\d+)?.png\">")

let longMessage = "<span class=\"s1\"><img src=\"file:///Attachment.png\" alt=\"Attachment.png\"></span><span class=\"s1\"><img src=\"file:///Attachment_1.png\" alt=\"Attachment_1.png\"></span>"

let matches = regex.matches(in: longMessage, range: NSMakeRange(0, (longMessage as NSString).length))
matches.count

var newText = longMessage
for i in 0..<matches.count {
    let m = matches[i]
    newText = (newText as NSString).replacingCharacters(in: m.range, with: "<img src=\"file:///MyAttachment\(i).jpg\" alt=\"MyAttachment\(i).jpg\">")
    print("range: \(m.range.location) newText: \(newText)\n")
}

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

var dict = [String: AnyObject]()
let key = "bool"
dict[key] = true as AnyObject?
dict[key]

Int16.max
Int16.min
