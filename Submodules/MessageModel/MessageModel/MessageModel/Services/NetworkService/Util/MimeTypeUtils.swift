//
//  MimeTypeUtils.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 08/02/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

//!!!: must go to interfaces or better: make internal
import Foundation
import MobileCoreServices

public typealias MimeType = String

//!!!: Must move to Interface
public class MimeTypeUtils {

    public struct MimesType {
        public static let defaultMimeType = "application/octet-stream"
        public static let jpeg = "image/jpeg"
        public static let pgp =  "application/pgp-signature"
        public static let pdf  = "application/pdf"
        public static let pgpEncrypted = "application/pgp-encrypted"
        public static let attachedEmail = "message/rfc822"
        public static let plainText = "text/plain"
        public static let pEpSync = "application/pep.sync"
        public static let pEpSign = "application/pep.sign"
    }

    private var mimeTypeToExtension = [MimeType: String]()

    public init?() {
        do {
            try setup()
        } catch {
            Log.shared.errorAndCrash(error: error)
            return nil
        }
    }

    public func fileExtension(fromMimeType mimeType: MimeType) -> String? {
        return mimeTypeToExtension[mimeType.lowercased()]
    }

    static public func mimeType(fromURL url: URL) -> MimeType {
        return MimeTypeUtils.mimeType(fromFileExtension: url.pathExtension)
    }

    /// Trys to figure out the best fitting MimeType for an attachment in case no specific MimiType
    /// is given (but "application/octet-stream").
    ///
    /// Currently only the file's extention is taken into account.
    ///
    /// - Parameters:
    ///   - url: url of file to figure the MimeType out for
    ///   - mimeType: the original mime type given in the mime-message-source
    /// - Returns:  the given mime type if it is specific (not "application/octet-stream") already,
    ///             otherwize the best MimeType we coud figure out
    static public func findBestMimeType(forFileAt url: URL,
                                        withGivenMimeType mimeType: MimeType?) -> MimeType? {
        if let mimeType = mimeType, mimeType != MimeTypeUtils.MimesType.defaultMimeType {
            // Is already a specific type, that is the best we can get.
            return mimeType
        }

        let foundMimeType: MimeType? = MimeTypeUtils.mimeType(fromFileExtension: url.pathExtension)

        return foundMimeType ?? mimeType
    }

    static public func mimeType(fromFileExtension fileExtension: String) -> MimeType {
        var foundMimeType: MimeType? = nil
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                           fileExtension as NSString,
                                                           nil)? .takeRetainedValue() {
            foundMimeType = (UTTypeCopyPreferredTagWithClass(uti,
                                                             kUTTagClassMIMEType)?
                .takeRetainedValue()) as MimeType?
        }

        return foundMimeType ?? MimeTypeUtils.MimesType.defaultMimeType
    }

    static public var unviewableMimeTypes: Set<MimeType> {
        get {
            return Set([ContentTypeUtils.ContentType.pgpKeys,
                        MimesType.pgp,
                        MimesType.pEpSync,
                        MimesType.pEpSign])
        }
    }

    /**
     Is the given mimetype suitable for creating an `UIImage`?
     */
    static public func isImage(mimeType theMimeType: String) -> Bool {
        let lcMT = theMimeType.lowercased()
        if lcMT == MimeTypeUtils.mimeType(fromFileExtension: "png") ||
            lcMT == MimeTypeUtils.mimeType(fromFileExtension: "jpg") ||
            lcMT == MimeTypeUtils.mimeType(fromFileExtension: "gif") {
            return true
        }
        return false
    }
}

// MARK: - Private

extension MimeTypeUtils {

    private enum MimeTypeUtilsError: Error {
        case jsonSerializationError
        case missingData
    }

    private func setup() throws {
        let resource = "jsonMimeType"
        let fileType = "txt"
        let bundle = Bundle(for: type(of:self))
        guard let file = bundle.path(forResource: resource, ofType: fileType) else {
            return
        }
        let data = try Data(contentsOf: URL(fileURLWithPath: file))
        guard let json = try JSONSerialization.jsonObject(with: data, options: [])
            as? [String: Any] else {
                throw MimeTypeUtilsError.jsonSerializationError
        }
        guard let theData = json["mimeType"] as? [String: String] else {
            throw MimeTypeUtilsError.missingData
        }
        for (theExtension, mimeType) in theData {
            mimeTypeToExtension[mimeType.lowercased()] = theExtension
        }
        // "image/jpeg" is missing in our data. Fix it.
        mimeTypeToExtension[MimeTypeUtils.MimesType.jpeg] = "jpg"
    }
}
