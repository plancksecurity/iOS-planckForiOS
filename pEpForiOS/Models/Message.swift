import Foundation
import CoreData

public protocol IMessage: _IMessage {
}

public extension IMessage {
    func imapMessage() -> CWIMAPMessage {
        let msg = CWIMAPMessage.init()
        if let sub = subject {
            msg.setSubject(sub)
        }
        if let uid = uid?.integerValue {
            msg.setUID(UInt(uid))
        }
        if let msn = messageNumber?.integerValue {
            msg.setMessageNumber(UInt(msn))
        }
        let fol = CWFolder.init(name: folder.name)
        msg.setFolder(fol)
        return msg
    }
}

@objc(Message)
public class Message: _Message, IMessage {
}
