import Foundation

public protocol IAttachment: _IAttachment, CustomStringConvertible, CustomDebugStringConvertible {
}

@objc(Attachment)
public class Attachment: _Attachment, IAttachment {
	// Custom logic goes here.

    override public var description: String {
        let s = NSMutableString()
        s.appendString("Part \(size) bytes")
        if let fn = filename {
            s.appendString(", \(fn)")
        }
        if let ct = contentType {
            s.appendString(", \(ct)")
        }
        return String(s)
    }

    override public var debugDescription: String {
        return description
    }
}