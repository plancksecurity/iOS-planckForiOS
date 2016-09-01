import Foundation
import CoreData

public protocol IMessage: _IMessage {
}

@objc(Message)
public class Message: _Message, IMessage {
    /**
     - Returns: A `CWFlags object` for the given `NSNumber`
     */
    static public func pantomimeFlagsFromNumber(flags: NSNumber) -> CWFlags {
        if let fl = PantomimeFlag.init(rawValue: UInt(flags.integerValue)) {
            return CWFlags.init(flags: fl)
        }
        Log.errorComponent(
            "Message", errorString:
            "Could not convert \(flags.integerValue) to PantomimeFlag")
        return CWFlags.init()
    }

    /**
     - Returns: The current flags as String, like "\Deleted \Answered"
     */
    static func flagsStringFromNumber(flags: NSNumber) -> String {
        return pantomimeFlagsFromNumber(flags).asString()
    }
}

public extension IMessage {
    func allRecipienst() -> NSOrderedSet {
        let recipients: NSMutableOrderedSet = []
        recipients.addObjectsFromArray(to.array)
        recipients.addObjectsFromArray(cc.array)
        recipients.addObjectsFromArray(bcc.array)
        return recipients
    }

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

    /**
     Convert the `Message` into an `CWIMAPMessage`, belonging to the given folder.
     - Note: This does not handle attachments and many other fields.
     *It's just for quickly interfacing with Pantomime.*
     */
    func pantomimeMessageWithFolder(folder: CWIMAPFolder) -> CWIMAPMessage {
        let msg = CWIMAPMessage.init()

        if let date = receivedDate {
            msg.setReceivedDate(date)
        }

        if let sub = subject {
            msg.setSubject(sub)
        }

        if let str = messageID {
            msg.setMessageID(str)
        }

        msg.setUID(UInt(uid))

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
        collectContacts(cc, asPantomimeReceiverType: .CcRecipient,
                        intoTargetArray: &recipients)
        collectContacts(bcc, asPantomimeReceiverType: .BccRecipient,
                        intoTargetArray: &recipients)
        collectContacts(to, asPantomimeReceiverType: .ToRecipient,
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

    /**
     - Returns: Some string that identifies a mail, useful for logging.
     */
    func logString() -> String {
        let string = NSMutableString()

        let append = {
            if string.length > 1 {
                string.appendString(", ")
            }
        }

        string.appendString("(")
        if let msgID = messageID {
            append()
            string.appendString("messageID: \(msgID)")
        }
        string.appendString("\(uid.integerValue)")
        if let oDate = receivedDate {
            append()
            string.appendString("date: \(oDate)")
        }
        string.appendString(")")
        return string as String
    }

    /**
     Call this after any update to the flags. Cannot currently be automated
     with `didSet` etc. because of the use of protocols.
     */
    public func updateFlags() {
        let cwFlags = CWFlags.init()
        let allFlags: [(Bool, PantomimeFlag)] = [
            (flagSeen.boolValue, PantomimeFlag.Seen),
            (flagDraft.boolValue, PantomimeFlag.Draft),
            (flagRecent.boolValue, PantomimeFlag.Recent),
            (flagDeleted.boolValue, PantomimeFlag.Deleted),
            (flagAnswered.boolValue, PantomimeFlag.Answered),
            (flagFlagged.boolValue, PantomimeFlag.Flagged)]
        for (p, f) in allFlags {
            if p {
                cwFlags.add(f)
            }
        }
        flags = NSNumber.init(short: cwFlags.rawFlagsAsShort())
    }

    /**
     - Returns: `flags` as `CWFlags`
     */
    public func pantomimeFlags() -> CWFlags {
        return Message.pantomimeFlagsFromNumber(flags)
    }

    /**
     - Returns: `flagsFromServer` as `CWFlags`
     */
    public func pantomimeFlagsFromServer() -> CWFlags {
        return Message.pantomimeFlagsFromNumber(flagsFromServer)
    }

    /**
     - Returns: A tuple consisting of an IMAP command string for updating
     the flags for this message, and a dictionary suitable for using pantomime
     for the actual execution.
     */
    public func storeCommandForUpdate() -> (String, [NSObject : AnyObject]) {
        // Construct a very minimal pantomime dummy for the info dictionary
        let pantomimeMail = CWIMAPMessage.init()
        pantomimeMail.setUID(UInt(uid.integerValue))

        var dict: [NSObject : AnyObject] = [PantomimeMessagesKey:
            NSArray.init(object: pantomimeMail)]

        var result = "UID STORE \(uid) "
        if flags.integerValue == 0 && flagsFromServer != 0 {
            let flagsString = Message.flagsStringFromNumber(flagsFromServer)
            result += "-FLAGS.SILENT (\(flagsString))"
            dict[PantomimeFlagsKey] = Message.pantomimeFlagsFromNumber(flagsFromServer)
        } else {
            let flagsString = Message.flagsStringFromNumber(flags)
            result += "+FLAGS.SILENT (\(flagsString))"
            dict[PantomimeFlagsKey] = Message.pantomimeFlagsFromNumber(flags)
        }
        return (command: result, dictionary: dict)
    }
}