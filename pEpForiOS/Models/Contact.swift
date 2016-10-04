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

protocol IContactDisplay {
    var email: String { get }
    var name: String? { get }

    /**
     Short display string, only the user's name if possible.
     */
    func displayString() -> String

    /**
     The complete name and email, if possible.
     */
    func completeDisplayString() -> String
}

extension IContactDisplay {
    public func displayString() -> String {
        guard let n = name else {
            return email
        }
        if n.isEmpty {
            return email
        }
        return n
    }

    public func completeDisplayString() -> String {
        if let name = self.name {
            return "\(name) <\(email)>"
        }
        return email
    }
}

@objc(Contact)
open class Contact: _Contact, IContactDisplay {
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
