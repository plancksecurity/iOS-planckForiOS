import Foundation
import CoreData

@objc(Message)
public class Message: _Message {

    static func existingMessage(msg: CWIMAPMessage, context: NSManagedObjectContext) -> Message? {
        var predicates = [NSPredicate.init(format: "subject = %@ and sentDate = %@",
            msg.subject(), msg.receivedDate())]
        predicates.append(NSPredicate.init(format: "uid = %d and folder.name = %@",
            msg.UID(), msg.folder().name()))
        if let msgId = msg.messageID() {
            predicates.append(NSPredicate.init(format: "messageId = %@", msgId))
        }
        for p in predicates {
            if let mail = singleEntityWithName(entityName(), predicate: p, context: context) {
                let result = mail as! Message
                return result
            }
        }
        return nil
    }

}
