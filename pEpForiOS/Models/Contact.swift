import Foundation

public protocol IContact: _IContact {
    func displayString() -> String
}

extension IContact {
    public func displayString() -> String {
        if self.name?.characters.count > 0 {
            return name!
        } else {
            return email
        }
    }

    public mutating func updateFromEmail(email: String, name: String?) {
        self.email = email
        if let personal = name {
            self.name = personal.unquote()
        } else {
            self.name = nil
        }
    }
}

@objc(Contact)
public class Contact: _Contact, IContact {
}