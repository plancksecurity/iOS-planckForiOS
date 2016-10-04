import Foundation

public protocol IAttachment: _IAttachment, CustomStringConvertible, CustomDebugStringConvertible {
}

@objc(Attachment)
open class Attachment: _Attachment, IAttachment {
	// Custom logic goes here.

    override open var description: String {
        let s = NSMutableString()
        s.append("Part \(size) bytes")
        if let fn = filename {
            s.append(", \(fn)")
        }
        if let ct = contentType {
            s.append(", \(ct)")
        }
        return String(s)
    }

    override open var debugDescription: String {
        return description
    }
}
