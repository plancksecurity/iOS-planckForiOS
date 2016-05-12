import Foundation
import CoreData

public protocol IMessage: _IMessage {
}

@objc(Message)
public class Message: _Message, IMessage {
}
