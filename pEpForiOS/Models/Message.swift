import Foundation
import CoreData

public protocol IMessage: _IMessage {
}

@objc(Message)
open class Message: _Message, IMessage {
    /**
     - Returns: A `CWFlags object` for the given `NSNumber`
     */
    static open func pantomimeFlagsFromNumber(_ flags: NSNumber) -> CWFlags {
        if let fl = PantomimeFlag.init(rawValue: UInt(flags.intValue)) {
            return CWFlags.init(flags: fl)
        }
        Log.errorComponent(
            "Message", errorString:
            "Could not convert \(flags.intValue) to PantomimeFlag")
        return CWFlags.init()
    }

    /**
     - Returns: The current flags as String, like "\Deleted \Answered"
     */
    static func flagsStringFromNumber(_ flags: NSNumber) -> String {
        return pantomimeFlagsFromNumber(flags).asString()
    }
}

public extension IMessage {
    func allRecipienst() -> NSOrderedSet {
        let recipients: NSMutableOrderedSet = []
        recipients.addObjects(from: to.array)
        recipients.addObjects(from: cc.array)
        recipients.addObjects(from: bcc.array)
        return recipients
    }

    func internetAddressFromContact(_ contact: IContact) -> CWInternetAddress {
        return CWInternetAddress.init(personal: contact.name, address: contact.email)

    }

    func collectContacts(_ contacts: NSOrderedSet,
                         asPantomimeReceiverType receiverType: PantomimeRecipientType,
                                                 intoTargetArray target: inout [CWInternetAddress]) {
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
    func pantomimeMessageWithFolder(_ folder: CWIMAPFolder) -> CWIMAPMessage {
        let msg = CWIMAPMessage.init()

        if let date = receivedDate {
            msg.setReceivedDate(date as Date)
        }

        if let sub = subject {
            msg.setSubject(sub)
        }

        if let str = messageID {
            msg.setMessageID(str)
        }

        msg.setUID(UInt(uid))

        if let msn = messageNumber?.intValue {
            msg.setMessageNumber(UInt(msn))
        }

        if let boundary = boundary {
            msg.setBoundary(boundary.data(using: String.Encoding.ascii))
        }

        if let contact = from {
            msg.setFrom(internetAddressFromContact(contact))
        }

        var recipients: [CWInternetAddress] = []
        collectContacts(cc, asPantomimeReceiverType: .ccRecipient,
                        intoTargetArray: &recipients)
        collectContacts(bcc, asPantomimeReceiverType: .bccRecipient,
                        intoTargetArray: &recipients)
        collectContacts(to, asPantomimeReceiverType: .toRecipient,
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

        // Avoid roundtrips to the server, just set the flags directly.
        msg.flags().replace(with: CWFlags.init(number: flags))

        return msg
    }

    /**
     - Returns: Some string that identifies a mail, useful for logging.
     */
    func logString() -> String {
        let string = NSMutableString()

        let append = {
            if string.length > 1 {
                string.append(", ")
            }
        }

        string.append("(")
        if let msgID = messageID {
            append()
            string.append("messageID: \(msgID)")
        }
        string.append("\(uid.intValue)")
        if let oDate = receivedDate {
            append()
            string.append("date: \(oDate)")
        }
        string.append(")")
        return string as String
    }

    /**
     Call this after any update to the flags. Cannot currently be automated
     with `didSet` etc. because of the use of protocols.
     */
    public func updateFlags() {
        let cwFlags = CWFlags.init()
        let allFlags: [(Bool, PantomimeFlag)] = [
            (flagSeen.boolValue, PantomimeFlag.seen),
            (flagDraft.boolValue, PantomimeFlag.draft),
            (flagRecent.boolValue, PantomimeFlag.recent),
            (flagDeleted.boolValue, PantomimeFlag.deleted),
            (flagAnswered.boolValue, PantomimeFlag.answered),
            (flagFlagged.boolValue, PantomimeFlag.flagged)]
        for (p, f) in allFlags {
            if p {
                cwFlags.add(f)
            }
        }
        flags = NSNumber.init(value: cwFlags.rawFlagsAsShort() as Int16)
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
     - Note: The generated command will always simply overwrite the flags version
     on the server with the local one.
     */
    public func storeCommandForUpdate() -> (String, [AnyHashable: Any]) {
        // Construct a very minimal pantomime dummy for the info dictionary
        let pantomimeMail = CWIMAPMessage.init()
        pantomimeMail.setUID(UInt(uid.intValue))

        var dict: [AnyHashable: Any] = [PantomimeMessagesKey:
            NSArray.init(object: pantomimeMail)]

        var result = "UID STORE \(uid) "
        let flagsString = Message.flagsStringFromNumber(flags)
        result += "FLAGS.SILENT (\(flagsString))"

        dict[PantomimeFlagsKey] = Message.pantomimeFlagsFromNumber(flags)
        return (command: result, dictionary: dict)
    }
}
