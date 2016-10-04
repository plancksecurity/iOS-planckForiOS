import Foundation

public protocol IMessageReference: _IMessageReference {
}

@objc(MessageReference)
open class MessageReference: _MessageReference, IMessageReference {
	// Custom logic goes here.
}
