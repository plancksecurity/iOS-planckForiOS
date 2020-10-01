//
//  Attachment.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 12/10/16.
//  Copyright © 2016 pEp Security S.A. All rights reserved.
//

import Photos
import CoreData

public class Attachment: MessageModelObjectProtocol, ManagedObjectWrapperProtocol {

    // MARK: - ManagedObjectWrapperProtocol
    
    typealias T = CdAttachment
    let moc: NSManagedObjectContext
    let cdObject: T

    // MARK: - Life Cycle

    required init(cdObject: T, context: NSManagedObjectContext) {
        self.cdObject = cdObject
        self.moc = context
    }

    convenience public init(data: Data?,
                            mimeType: String,
                            fileName: String? = nil,
                            image: UIImage? = nil,
                            assetUrl: URL? = nil,
                            contentDisposition: ContentDispositionType = .attachment,
                            session: Session = Session.main) {
        let moc = session.moc
        let createe = CdAttachment(context: moc)
        createe.data = data
        createe.mimeType = mimeType.lowercased()
        createe.assetUrl = assetUrl?.absoluteString
        createe.fileName = fileName
        createe.contentDispositionTypeRawValue = contentDisposition.rawValue

        self.init(cdObject: createe, context: moc)
        self.image = image
    }

    // MARK: - Trtansient fields

    public var image: UIImage?

    // MARK: - Forwarded Getter & Setter

    public var data: Data? {
        get {
            return cdObject.data
        }
        set {
            cdObject.data = newValue
        }
    }

    public var mimeType: String? {
        get {
            return cdObject.mimeType
        }
        set {
            cdObject.mimeType = newValue?.lowercased()
        }
    }

    public var contentDisposition: ContentDispositionType {
        get {
            return ContentDispositionType(rawValue: cdObject.contentDispositionTypeRawValue)!
        }
        set {
            cdObject.contentDispositionTypeRawValue = newValue.rawValue
        }
    }

    /// The Engine offers only one field (filename) which is used for filename or contentID. If both
    /// values are available, contentID wins. The filename is lost in this case. The format can be
    /// the filename (arbitrary string) or an URL, either in the form `file://` one or `cid:`.
    public var fileName: String? {
        get {
            return cdObject.fileName
        }
        set {
            cdObject.fileName = newValue
        }
    }

    /**
     For attached photos, this is the URL the attachment came from.
     This is an internal piece of data, this information will not leave the device.
     */
    public var assetUrl: URL? {
        get {
            guard let urlString = cdObject.assetUrl else {
                return nil
            }
            return URL(string: urlString)
        }
        set {
            cdObject.assetUrl = newValue?.absoluteString
        }
    }

    public var message: Message? {
        get{
            guard let cdMessage = cdObject.message else {
                return nil
            }
            return MessageModelObjectUtils.getMessage(fromCdMessage: cdMessage)
        }
        set {
            cdObject.message = newValue?.cdObject
        }
    }
}

// MARK: - Hashable

extension Attachment: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(data)
        hasher.combine(fileName)
        hasher.combine(size)
        hasher.combine(mimeType)
    }
}

// MARK: - Comparing

extension Attachment {
    public static func ==(lhs: Attachment, rhs: Attachment) -> Bool {
        return lhs.data == rhs.data && lhs.fileName == rhs.fileName && lhs.size == rhs.size &&
            lhs.mimeType == rhs.mimeType && lhs.contentDisposition == rhs.contentDisposition
    }
}

// MARK: - Debug strings

extension Attachment: CustomDebugStringConvertible {
    public var debugDescription: String {
        let sizeString = "\(String(describing: size))"
        return "Attachment mimeType: \(mimeType ?? "nil") fileName: \(fileName ?? "nil") size: \(sizeString)"
    }
}

// MARK: - FETCHING

extension Attachment {

    /// - note: MUST be used on the main queue ONLY
    static public func by(cid: String) -> Attachment? {
        let contentIdPrefix = Attachment.contentIdUrlScheme + "://"
        let filename = contentIdPrefix + cid
        return CdAttachment.by(filename: filename, context: Stack.shared.mainContext)?.attachment()
    }
}

extension Attachment {
    static public let contentIdUrlScheme = "cid"

    public var size: Int? {
        get {
            return cdObject.data?.count
        }
    }
}
