//
//  MimeTypeUtils+MimeType.swift
//  MessageModel
//
//  Created by Andreas Buff on 29.09.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

// MARK: - MimeTypeUtils+MimeType

public typealias MimeTypeString = String

extension MimeTypeUtils {

    public enum MimeType: String {
        case defaultMimeType = "application/octet-stream"

        case pgpKeys = "application/pgp-keys"
        case html = "text/html"

        case jpeg = "image/jpeg"
        case pgp =  "application/pgp-signature"
        case pdf  = "application/pdf"
        case pgpEncrypted = "application/pgp-encrypted"
        case attachedEmail = "message/rfc822"
        case plainText = "text/plain"
        case pEpSync = "application/pep.sync"
        case pEpSign = "application/pep.sign"
        case xml = "text/xml"
        case csv = "text/csv"
        case rtf = "text/rtf"

        // Microsoft Office
        case msword, dot, word, w6w = "application/msword"
        case docx = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case dotx = "application/vnd.openxmlformats-officedocument.wordprocessingml.template"
        case docm, dotm = "application/vnd.ms-word.document.macroenabled.12"

        case xls, xlt, xla, xlw = "application/msexcel"
        case xlsx = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case xltx = "application/vnd.openxmlformats-officedocument.spreadsheetml.template"

        case thunderbirdAttachedXls = "application/vnd.ms-excel"
        case xlsm = "application/vnd.ms-excel.sheet.macroenabled.12"
        case xlsb = "application/vnd.ms-excel.sheet.binary.macroenabled.12"
        case xltm = "application/vnd.ms-excel.template.macroenabled.12"
        case xlam = "application/vnd.ms-excel.addin.macroenabled.12"

        case ppt, pot, pps, ppa = "application/mspowerpoint"
        case pptx = "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        case potx = "application/vnd.openxmlformats-officedocument.presentationml.template"
        case ppsx = "application/vnd.openxmlformats-officedocument.presentationml.slideshow"
        case ppam = "application/vnd.ms-powerpoint.addin.macroenabled.12"
        case pptm = "application/vnd.ms-powerpoint.presentation.macroenabled.12"
        case ppsm = "application/vnd.ms-powerpoint.slideshow.macroenabled.12"
        case potm = "application/vnd.ms-powerpoint.template.macroenabled.12"

        case mdb, accda, accdb, accde, accdr, accdt, ade, adp, adn, mde, mdf, mdn, mdt, mdw = "application/msaccess"
        case wri = "application/mswrite"

        public init?(rawValueIgnoringCase: String) {
            let lowercased = rawValueIgnoringCase.lowercased()
            self.init(rawValue: lowercased)
        }
    }
}
