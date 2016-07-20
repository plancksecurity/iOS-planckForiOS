import Foundation

public protocol IContact: _IContact {
    /**
     Short display string, only the user's name if possible.
     */
    func displayString() -> String

    /**
     The complete name and email, if possible.
     */
    func completeDisplayString() -> String
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

    /**
     Updates that contact's name if the new value is non-nil and the existing
     value is nil. Otherwise, the original one is kept.
     */
    public func updateName(name: String?) {
        if let personal = name {
            if self.name == nil {
                self.name = personal.unquote()
            }
        }
    }
}

@objc(Contact)
public class Contact: _Contact, IContact {
}