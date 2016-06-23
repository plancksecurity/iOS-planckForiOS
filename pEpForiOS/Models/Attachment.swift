import Foundation

public protocol IAttachment: _IAttachment {
}

@objc(Attachment)
public class Attachment: _Attachment, IAttachment {
	// Custom logic goes here.
}