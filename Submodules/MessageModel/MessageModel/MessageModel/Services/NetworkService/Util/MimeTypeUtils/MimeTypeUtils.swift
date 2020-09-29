//
//  MimeTypeUtils.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 08/02/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MobileCoreServices

//!!!: Must move to Interface. Refactor.
public class MimeTypeUtils {
    private var mimeTypeToExtension = [MimeTypeString: String]() //BUFF: move

    public init?() {
        do {
            try setup()
        } catch {
            Log.shared.errorAndCrash(error: error)
            return nil
        }
    }

    public func fileExtension(fromMimeType mimeType: MimeTypeString) -> String? { //BUFF: move
        return mimeTypeToExtension[mimeType.lowercased()]
    }

    static public func mimeType(fromURL url: URL) -> MimeTypeString {
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
                                        withGivenMimeType mimeType: MimeTypeString?) -> MimeType? {
        if let mimeType = mimeType, mimeType != MimeTypeUtils.MimeType.defaultMimeType.rawValue {
            // Is already a specific type, that is the best we can get.
            return MimeType(rawValue: mimeType)
        }
        let foundMimeTypeString = MimeTypeUtils.mimeType(fromFileExtension: url.pathExtension)
        return MimeType(rawValue: foundMimeTypeString)
    }

    static public func mimeType(fromFileExtension fileExtension: String) -> MimeTypeString {
        var foundMimeType: MimeTypeString? = nil
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                           fileExtension as NSString,
                                                           nil)? .takeRetainedValue() {
            foundMimeType = (UTTypeCopyPreferredTagWithClass(uti,
                                                             kUTTagClassMIMEType)?
                .takeRetainedValue()) as MimeTypeString?
        }

        return foundMimeType ?? MimeTypeUtils.MimeType.defaultMimeType.rawValue
    }

    static public var unviewableMimeTypes: Set<MimeTypeString> {
        return Set([MimeType.pgpKeys.rawValue,
                    MimeType.pgp.rawValue,
                    MimeType.pEpSync.rawValue,
                    MimeType.pEpSign.rawValue])
    }

    /**
     Is the given mimetype suitable for creating an `UIImage`?
     */
    static public func isImage(mimeType theMimeType: String) -> Bool { //BUFF: move
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
        mimeTypeToExtension[MimeTypeUtils.MimeType.jpeg.rawValue] = "jpg"
    }
}
