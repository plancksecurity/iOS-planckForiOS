//
//  String+PEPSignature.swift
//  MessageModel
//
//  Created by Alejandro Gelos on 17/07/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

extension String {
    public static var pepSignature: String {
        let bottom = NSLocalizedString("sent with p≡p",
                                       comment: "pEp mail signature. Newlines will be added by app")
        return "\n\n\(bottom)\n"
    }

    public static var pEpSignatureHtml: String {
        let pEpSignatureTrimmed = String.pepSignature.trimmed()
        return "<a href=\"https://pep.software\" style=\"color:\(UIColor.pEpDarkGreenHex); text-decoration: none;\">\(pEpSignatureTrimmed)</a>"
    }

    public func replacingOccurrencesOfPepSignatureWithHtmlVersion() -> String {
        let pEpSignatureTrimmed = String.pepSignature.trimmed()
        return replacingOccurrences(of: pEpSignatureTrimmed, with: String.pEpSignatureHtml)
    }
}
