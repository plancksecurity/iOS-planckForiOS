import Foundation

@objc(Contact)
public class Contact: _Contact {
    let comp = "Contact"

    func displayString() -> String {
        if self.name?.characters.count > 0 {
            return name!
        } else {
            return email
        }
    }

    func updateFromInternetAddress(address: CWInternetAddress) {
        self.email = address.address()
        if let personal = address.personal() {
            self.name = personal.unquote()
        } else {
            self.name = nil
        }
    }
}
