import Foundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


public protocol IContact {
    var email: String { get set }
    var name: String? { get set }
    var addressBookID: NSNumber? { get set }
    var pepUserID: String? { get set }
    var isMySelf: NSNumber { get set }
    var bccMessages: NSSet { get set }
    var ccMessages: NSSet { get set }
    var toMessages: NSSet { get set }
    var fromMessages: NSSet { get set }

    /**
     Short display string, only the user's name if possible.
     */
    func displayString() -> String

    /**
     The complete name and email, if possible.
     */
    func completeDisplayString() -> String
}

@objc(Contact)
open class Contact: _Contact, IContact {
}

extension IContact {
    public func displayString() -> String {
        if self.name?.characters.count > 0 {
            return name!
        } else {
            return email
        }
    }

    public func completeDisplayString() -> String {
        if let name = self.name {
            return "\(name) <\(email)>"
        }
        return email
    }
}

extension Contact {
    /**
     Updates that contact's name if the new value is non-nil and the existing
     value is nil. Otherwise, the original one is kept.
     */
    public func updateName(_ name: String?) {
        if let personal = name {
            if self.name == nil {
                self.name = personal.unquote()
            }
        }
    }
}
