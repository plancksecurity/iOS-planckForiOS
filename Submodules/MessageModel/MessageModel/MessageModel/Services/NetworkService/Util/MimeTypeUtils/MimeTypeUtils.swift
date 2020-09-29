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

//!!!: Must move to Interface. Refactor.
public class MimeTypeUtils {

    public enum MimesType: String {
        case defaultMimeType = "application/octet-stream"

        case pgpKeys = "application/pgp-keys"
        case html = "text/html"
        case multipartMixed = "multipart/mixed"
        case multipartEncrypted = "multipart/encrypted"
        case multipartRelated = "multipart/related"
        case multipartAlternative = "multipart/alternative"

        case jpeg = "image/jpeg"
        case pgp =  "application/pgp-signature"
        case pdf  = "application/pdf"
        case pgpEncrypted = "application/pgp-encrypted"
        case attachedEmail = "message/rfc822"
        case plainText = "text/plain"
        case pEpSync = "application/pep.sync"
        case pEpSign = "application/pep.sign"
        // Microsoft Office
        // Microsoft Office
        case msword, dot, word, w6w = "application/msword"
        case docx = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case dotx = "application/vnd.openxmlformats-officedocument.wordprocessingml.template"
        case docm, dotm = "application/vnd.ms-word.document.macroEnabled.12"

        case xls, xlt, xla, xlw = "application/msexcel"
        case xlsx = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case xltx = "application/vnd.openxmlformats-officedocument.spreadsheetml.template"

        case xlsm = "application/vnd.ms-excel.sheet.macroEnabled.12"
        case xlsb = "application/vnd.ms-excel.sheet.binary.macroEnabled.12"
        case xltm = "application/vnd.ms-excel.template.macroEnabled.12"
        case xlam = "application/vnd.ms-excel.addin.macroEnabled.12"

        case ppt, pot, pps, ppa = "application/mspowerpoint"
        case pptx = "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        case potx = "application/vnd.openxmlformats-officedocument.presentationml.template"
        case ppsx = "application/vnd.openxmlformats-officedocument.presentationml.slideshow"
        case ppam = "application/vnd.ms-powerpoint.addin.macroEnabled.12"
        case pptm = "application/vnd.ms-powerpoint.presentation.macroEnabled.12"
        case ppsm = "application/vnd.ms-powerpoint.slideshow.macroEnabled.12"
        case potm = "application/vnd.ms-powerpoint.template.macroEnabled.12"


        case mdb, accda, accdb, accde, accdr, accdt, ade, adp, adn, mde, mdf, mdn, mdt, mdw = "application/msaccess"
        case wri = "application/mswrite"
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
        if let mimeType = mimeType, mimeType != MimeTypeUtils.MimesType.defaultMimeType.rawValue {
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

        return foundMimeType ?? MimeTypeUtils.MimesType.defaultMimeType.rawValue
    }

    static public var unviewableMimeTypes: Set<MimeType> {
        return Set([MimesType.pgpKeys.rawValue,
                    MimesType.pgp.rawValue,
                    MimesType.pEpSync.rawValue,
                    MimesType.pEpSign.rawValue])
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

// MARK: - Microsoft Office

extension MimeTypeUtils.MimesType {

    //    public var isMicrosoftOfficeMimeType: String {
    //        // Microsoft Office
    //        case msword, dot, word, w6w = "application/msword"
    //        case docx = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    //        case dotx = "application/vnd.openxmlformats-officedocument.wordprocessingml.template"
    //        case docm, dotm = "application/vnd.ms-word.document.macroEnabled.12"
    //
    //        case xls, xlt, xla, xlw = "application/msexcel"
    //        case xlsx = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    //        case xltx = "application/vnd.openxmlformats-officedocument.spreadsheetml.template"
    //
    //        case xlsm = "application/vnd.ms-excel.sheet.macroEnabled.12"
    //        case xlsb = "application/vnd.ms-excel.sheet.binary.macroEnabled.12"
    //        case xltm = "application/vnd.ms-excel.template.macroEnabled.12"
    //        case xlam = "application/vnd.ms-excel.addin.macroEnabled.12"
    //
    //        case ppt, pot, pps, ppa = "application/mspowerpoint"
    //        case pptx = "application/vnd.openxmlformats-officedocument.presentationml.presentation"
    //        case potx = "application/vnd.openxmlformats-officedocument.presentationml.template"
    //        case ppsx = "application/vnd.openxmlformats-officedocument.presentationml.slideshow"
    //        case ppam = "application/vnd.ms-powerpoint.addin.macroEnabled.12"
    //        case pptm = "application/vnd.ms-powerpoint.presentation.macroEnabled.12"
    //        case ppsm = "application/vnd.ms-powerpoint.slideshow.macroEnabled.12"
    //        case potm = "application/vnd.ms-powerpoint.template.macroEnabled.12"
    //
    //
    //        case mdb, accda, accdb, accde, accdr, accdt, ade, adp, adn, mde, mdf, mdn, mdt, mdw = "application/msaccess"
    //        case wri = "application/mswrite"
    //        }

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
        mimeTypeToExtension[MimeTypeUtils.MimesType.jpeg.rawValue] = "jpg"
    }
}
