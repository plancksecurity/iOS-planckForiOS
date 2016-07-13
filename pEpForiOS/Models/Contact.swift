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

/**
 For sharing core data contacts between threads, when the core data identity is not important.
 */
public class ContactDAO: IContact {
    public var email: String
    public var name: String? = nil
    public var userID: String? = nil
    public var bccMessages: NSSet = NSSet()
    public var ccMessages: NSSet = NSSet()
    public var fromMessages: NSSet = NSSet()
    public var toMessages: NSSet = NSSet()

    public init(contact: IContact) {
        email = contact.email
        name = contact.name
        userID = contact.userID
    }

    public init(email: String) {
        self.email = email
    }
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