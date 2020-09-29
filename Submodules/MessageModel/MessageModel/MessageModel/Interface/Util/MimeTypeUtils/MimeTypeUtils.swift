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
    private var mimeTypeToExtension = [MimeTypeString: String]()

    public init?() {
        do {
            try setup()
        } catch {
            Log.shared.errorAndCrash(error: error)
            return nil
        }
    }

    public func fileExtension(fromMimeType mimeType: MimeTypeString) -> String? {
        return mimeTypeToExtension[mimeType.lowercased()]
    }

    static public func mimeType(fromURL url: URL) -> MimeTypeString {
        return MimeTypeUtils.mimeType(fromFileExtension: url.pathExtension)
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
    static public func isImage(mimeType: String) -> Bool {
        let lcMimeType = mimeType.lowercased()
        if lcMimeType == MimeTypeUtils.mimeType(fromFileExtension: "png") ||
            lcMimeType == MimeTypeUtils.mimeType(fromFileExtension: "jpg") ||
            lcMimeType == MimeTypeUtils.mimeType(fromFileExtension: "gif") {
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
