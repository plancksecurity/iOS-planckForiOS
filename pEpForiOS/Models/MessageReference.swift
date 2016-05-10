import Foundation

public protocol IMessageReference: _IMessageReference {
}

@objc(MessageReference)
public class MessageReference: _MessageReference, IMessageReference {
	// Custom logic goes here.
}
