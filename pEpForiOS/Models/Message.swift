import Foundation
import CoreData

public protocol IMessage: _IMessage {
}

@objc(Message)
public class Message: _Message, IMessage {
}

public extension IMessage {
    func internetAddressFromContact(contact: IContact) -> CWInternetAddress {
        return CWInternetAddress.init(personal: contact.name, address: contact.email)

    }

    func collectContacts(contacts: NSOrderedSet,
                         asPantomimeReceiverType receiverType: PantomimeRecipientType,
                                                 inout intoTargetArray target: [CWInternetAddress]) {
        for obj in contacts {
            if let theContact = obj as? IContact {
                let addr = internetAddressFromContact(theContact)
                addr.setType(receiverType)
                target.append(addr)
            }
        }
    }

    func imapMessageWithFolder(folder: CWIMAPFolder) -> CWIMAPMessage {
        let msg = CWIMAPMessage.init()

        if let date = originationDate {
            msg.setReceivedDate(date)
        }

        if let sub = subject {
            msg.setSubject(sub)
        }

        if let str = messageID {
            msg.setMessageID(str)
        }

        if let uid = uid?.integerValue {
            msg.setUID(UInt(uid))
        }

        if let msn = messageNumber?.integerValue {
            msg.setMessageNumber(UInt(msn))
        }

        if let boundary = boundary {
            msg.setBoundary(boundary.dataUsingEncoding(NSASCIIStringEncoding))
        }

        if let contact = from {
            msg.setFrom(internetAddressFromContact(contact))
        }

        var recipients: [CWInternetAddress] = []
        collectContacts(cc, asPantomimeReceiverType: PantomimeCcRecipient,
                        intoTargetArray: &recipients)
        collectContacts(bcc, asPantomimeReceiverType: PantomimeBccRecipient,
                        intoTargetArray: &recipients)
        collectContacts(to, asPantomimeReceiverType: PantomimeToRecipient,
                        intoTargetArray: &recipients)
        msg.setRecipients(recipients)

        var refs: [String] = []
        for ref in references {
            let refString: String = (ref as! MessageReference).messageID
            refs.append(refString)
        }
        msg.setReferences(refs)

        msg.setContentType(contentType)

        msg.setFolder(folder)

        return msg
    }
}