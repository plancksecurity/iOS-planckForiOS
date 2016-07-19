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

    public func updateFromEmail(
        email: String, name: String?, addressBookID: Int32? = nil) {
        self.email = email
        if let personal = name {
            self.name = personal.unquote()
        } else {
            self.name = nil
        }
        if let ident = addressBookID {
            self.addressBookID = NSNumber.init(int: ident)
        } else {
            self.addressBookID = nil
        }
    }
}

@objc(Contact)
public class Contact: _Contact, IContact {
}